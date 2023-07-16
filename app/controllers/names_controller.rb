# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require "open-uri"

#   Names are central to the NSL.
class NamesController < ApplicationController
  include OpenURI
  # All text/html requests should go to the search page, except for rules.
  before_action :javascript_only, except: [:rules, :refresh_children]
  before_action :find_name,
                only: [:show, :tab, :edit_as_category,
                       :refresh, :refresh_children, :transfer_dependents]

  # GET /names/1
  # GET /names/1.json
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    logger.debug("NamesController#show")
    pick_a_tab("tab_details")
    pick_a_tab_index
    if params[:change_category_name_to].present?
      @name.change_category_name_to = "scientific"
    end
    if params[:tab] =~ /\Atab_instances\z/
      @instance = Instance.new
      @instance.name = @name
    end
    @take_focus = params[:take_focus] == 'true'
    render "show", layout: false
  end

  alias tab show

  # Used on references - new instance tab
  def typeahead_on_full_name
    typeahead = Name::AsTypeahead::OnFullName.new(params)
    render json: typeahead.suggestions
  end

  # For the typeahead search.
  def name_parent_suggestions
    typeahead = Name::AsTypeahead::ForParent.new(params)
    render json: typeahead.suggestions
  end

  def name_family_suggestions
    typeahead = Name::AsTypeahead::ForFamily.new(params)
    render json: typeahead.suggestions
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def cultivar_parent_suggestions
    render json: [] if params[:term].blank?
    render json: Name::AsTypeahead\
      .cultivar_parent_suggestions(params[:term],
                                   params[:name_id],
                                   params[:rank_id])
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def hybrid_parent_suggestions
    render json: [] if params[:term].blank?
    render json: Name::AsTypeahead\
      .hybrid_parent_suggestions(params[:term],
                                 params[:name_id],
                                 params[:rank_id])
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def duplicate_suggestions
    render json: duplicate_suggestions_typeahead
  end

  def edit_as_category
    @tab = "tab_edit"
    @tab_index = 1
    if params[:new_category].present?
      @name.change_category_name_to = params[:new_category]
    else
      throw 'No new category param'
    end
    render "show", layout: false
  end

  # GET /names/new_row
  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    @category = params[:type].tr("-", " ")
    logger.debug("@category: #{@category}")
    respond_to do |format|
      format.html {redirect_to new_search_path}
      format.js {}
    end
  end

  # GET /names/new
  def new
    logger.debug("new name")
    @tab_index = (params[:tabIndex] || "40").to_i
    @name = new_name_for_category
    @no_search_result_details = true
    render "new"
  end

  # POST /names
  def create
    @name = Name::AsEdited.create(name_params,
                                  typeahead_params,
                                  current_user.username)
    render "create"
  rescue => e
    logger.error("Controller:Names:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: 422
  end

  # PUT /names/1.json
  # Ajax only.
  def update
    @name = Name::AsEdited.find(params[:id])
    refresh_after_update = refresh_names_after_update?
    @message = @name.update_if_changed(name_params,
                                       typeahead_params,
                                       current_user.username)
    refresh_names if refresh_after_update
    render "update"
  rescue => e
    @message = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  def rules
    empty_search
    hide_details
  end

  def copy
    logger.debug("copy")
    current_name = Name::AsCopier.find(params[:id])
    @name = current_name.copy_with_username(name_params[:name_element],
                                            current_user.username)
    render "names/copy/success"
  rescue => e
    @message = e.to_s
    logger.error("Error in Name#copy: #{@message}")
    render "names/copy/error"
  end

  def refresh
    @name.set_names!
    render "names/refresh/ok"
  rescue => e
    @message = e.to_s
    render "names/refresh/error"
  end

  def refresh_name_path_field
    @name = Name::AsEdited.find(params[:id])
    @name.build_name_path
    if @name.changed?
      @name.save!(touch: false)
      render "names/refresh_name_path/ok"
    else
      render "names/refresh_name_path/no_change"
    end
  rescue => e
    @message = e.to_s
    render "names/refresh_name_path/error"
  end

  def refresh_children
    if @name.combined_children.size > 50
      NameChildrenRefresherJob.new.perform(@name.id)
      render "names/refresh_children/job_started"
    else
      @total = NameChildrenRefresherJob.new.perform(@name.id)
      render "names/refresh_children/ok"
    end
  rescue => e
    @message = e.to_s
    render "names/refresh_children/error"
  end

  def transfer_dependents
    @dependent_type = dependent_params[:dependent_type]
    count = @name.transfer_dependents(@dependent_type)
    @message = "#{count} transferred"
    render 'names/de_duplication/transfer_dependents/success'
  rescue => e
    @message = e.to_s.sub(/uncaught throw/,'').sub(/\A *"/,'').sub(/" *\z/,'')
    render 'names/de_duplication/transfer_dependents/error'
  end
 
  def transfer_all_dependents
    @dependent_type = dependent_params[:dependent_type]
    count = Name.transfer_all_dependents(@dependent_type)
    @message = "#{count} transferred"
    render 'names/de_duplication/transfer_all_dependents/success'
  rescue => e
    @message = e.to_s.sub(/uncaught throw/,'').sub(/\A *"/,'').sub(/" *\z/,'')
    render 'names/de_duplication/transfer_all_dependents/error'
  end
  private

  def find_name
    @name = Name.includes(:name_type,
                          :name_status,
                          :name_rank,
                          :instances,
                          :author,
                          :ex_author,
                          :base_author,
                          :duplicate_of,
                          :ex_base_author,
                          :name_tags,
                          :comments).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Could not find the name."
    redirect_to names_path
  end

  def find_name_as_services
    @name = Name::AsServices.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Could not find the name."
    redirect_to names_path
  end

  def duplicate_suggestions_typeahead
    return [] if params[:term].blank?
    return [] if params[:name_id].blank?
    Name::AsTypeahead.duplicate_suggestions(params[:term],
                                            params[:name_id])
  end

  def new_name_for_category
    case params[:category]
    when "scientific" then
      Name::AsNew.scientific
    when "scientific_family" then
      Name::AsNew.scientific_family
    when "phrase" then
      Name::AsNew.phrase
    when "hybrid formula" then
      Name::AsNew.scientific_hybrid
    when "hybrid formula unknown 2nd parent"
      Name::AsNew.scientific_hybrid_unknown_2nd_parent
    when "cultivar hybrid" then
      Name::AsNew.cultivar_hybrid
    when "cultivar" then
      Name::AsNew.cultivar
    else
      Name::AsNew.other
    end
  end

  def refresh_names_after_update?
    @name.name_element != name_params[:name_element]
  end

  def refresh_names
    NameChildrenRefresherJob.new.perform(@name.id)
  end

  def name_params
    params.require(:name).permit(:name_status_id,
                                 :name_rank_id,
                                 :name_type_id,
                                 :name_element,
                                 :verbatim_rank,
                                 :published_year,
                                 :changed_combination)
  end

  def typeahead_params
    params.require(:name).permit(:author_id,
                                 :ex_author_id,
                                 :base_author_id,
                                 :ex_base_author_id,
                                 :sanctioning_author_id,
                                 :author_typeahead,
                                 :ex_author_typeahead,
                                 :base_author_typeahead,
                                 :ex_base_author_typeahead,
                                 :sanctioning_author_typeahead,
                                 :family_id,
                                 :family_typeahead,
                                 :parent_id,
                                 :second_parent_id,
                                 :parent_typeahead,
                                 :second_parent_typeahead,
                                 :duplicate_of_id,
                                 :duplicate_of_typeahead)
  end

  def dependent_params
    params.permit(:id, :dependent_type)
  end
end
