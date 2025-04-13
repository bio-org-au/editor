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
  include Name::Typeaheads
  # All text/html requests should go to the search page, except for rules.
  before_action :javascript_only, except: %i[rules refresh_children]
  before_action :find_name,
                only: %i[show tab edit_as_category
                         refresh refresh_children transfer_dependents]

  # GET /names/1
  # GET /names/1.json
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    logger.debug("NamesController#show")
    pick_a_tab("tab_details")
    pick_a_tab_index
    @name.change_category_name_to = "scientific" if params[:change_category_name_to].present?
    if params[:tab] == "tab_instances" || params[:tab] == "tab_instances_profile_v2"
      @instance = Instance.new
      @instance.name = @name
    end
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  alias tab show

  def edit_as_category
    @tab = "tab_edit"
    @tab_index = 1
    if params[:new_category].present?
      @name.change_category_name_to = params[:new_category]
    else
      throw "No new category param"
    end
    render "show", layout: false
  end

  # GET /names/new_row
  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    @category = params[:type].tr(" ", "-")
    @category_display = params[:type].tr("-", " ")
    render :new_row,
      locals: {partial: 'new_row',
               locals_for_partial:
          {tab_path: "#{new_name_with_category_and_random_id_path(@category, @random_id)}",
           link_id: "link-new-name-#{@category}-#{@random_id}",
           link_title: new_row_link_title,
           link_text: new_row_link_text,
           name_category: @category
          }
              }
  end

  # GET /names/new
  def new
    @tab_index = (params[:tabIndex] || "40").to_i
    @category = params[:category]
    @category_display = @category.gsub(/[_-]/,' ')
    @name = new_name_for_category
    @no_search_result_details = true
    render :new
  end

  # POST /names
  def create
    @name = Name::AsEdited.create(name_params,
                                  typeahead_params,
                                  current_user.username)
    render "create"
  rescue StandardError => e
    logger.error("Controller:Names:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: 422
  end

  # PUT /names/1.json
  # Ajax only.
  def update
    @name = Name::AsEdited.find(params[:id])
    name_before_change = @name.dup
    @message = @name.update_if_changed(name_params,
                                       typeahead_params,
                                       current_user.username)
    check_children(name_before_change) unless @message.downcase == 'no change'
    render "update"
  rescue StandardError => e
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
  rescue StandardError => e
    @message = e.to_s
    logger.error("Error in Name#copy: #{@message}")
    render "names/copy/error"
  end

  def refresh
    @name.set_names!
    render "names/refresh/ok"
  rescue StandardError => e
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
  rescue StandardError => e
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
  rescue StandardError => e
    @message = e.to_s
    render "names/refresh_children/error"
  end

  def transfer_dependents
    @dependent_type = dependent_params[:dependent_type]
    count = @name.transfer_dependents(@dependent_type)
    @message = "#{count} transferred"
    render "names/de_duplication/transfer_dependents/success"
  rescue StandardError => e
    @message = e.to_s.sub("uncaught throw", "").sub(/\A *"/, "").sub(/" *\z/, "")
    render "names/de_duplication/transfer_dependents/error"
  end

  def transfer_all_dependents
    @dependent_type = dependent_params[:dependent_type]
    count = Name.transfer_all_dependents(@dependent_type)
    @message = "#{count} transferred"
    render "names/de_duplication/transfer_all_dependents/success"
  rescue StandardError => e
    @message = e.to_s.sub("uncaught throw", "").sub(/\A *"/, "").sub(/" *\z/, "")
    render "names/de_duplication/transfer_all_dependents/error"
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
    when /scientific\z/
      Name::AsNew.scientific
    when /scientific.family.or.above/
      Name::AsNew.scientific_family_or_above
    when "phrase"
      Name::AsNew.phrase
    when /hybrid.formula\z/
      Name::AsNew.scientific_hybrid
    when /hybrid.formula.unknown.2nd.parent/
      Name::AsNew.scientific_hybrid_unknown_2nd_parent
    when /cultivar.hybrid/
      Name::AsNew.cultivar_hybrid
    when /cultivar\z/
      Name::AsNew.cultivar
    else
      Name::AsNew.other
    end
  end

  def check_children(name_before_change)
    if @name.simple_name != name_before_change.simple_name ||
         @name.full_name != name_before_change.full_name ||
         @name.name_path != name_before_change.name_path
      refresh_names
    end
  end

  def refresh_names
    refreshed_names_tally = 0
    refreshed_names_tally = NameChildrenRefresherJob.new.perform(@name.id)
    if refreshed_names_tally > 0
      @message += "; also updated \
      #{ActionController::Base.helpers.pluralize(refreshed_names_tally,\
      'child')}."
    end
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

  def dependent_params
    params.permit(:id, :dependent_type)
  end

  def new_row_link_title
    return "New #{@category_display} Name" unless @category.match(/family-or/)

    "New Scientific Name - Family or Above"
  end

  def new_row_link_text
    return "New #{@category_display} Name".titleize unless @category.match(/family-or/)

    "New Scientific Name - Family or Above"
  end
end
