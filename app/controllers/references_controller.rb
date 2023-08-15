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
class ReferencesController < ApplicationController
  before_action :find_reference, only: %i[edit update destroy show tab]

  # GET /references/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    pick_a_tab
    pick_a_tab_index
    copy_reference if @tab == "tab_copy"
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  alias tab show

  # GET /references/new
  def new
    @reference = Reference::AsNew.default
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    render "new"
  end

  # GET /references/new_row
  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  # POST /references
  def create
    check_date_params
    @reference = Reference::AsEdited.create(reference_params,
                                            typeahead_params,
                                            current_user.username)
    render "create"
  rescue StandardError => e
    logger.error("Controller:reference:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_entity
  end

  # PUT /references/1.json
  # Ajax only
  # Makes this compatible with create error processing.
  def update
    check_date_params
    @form = params[:form][:name] if params[:form]
    update_reference
    render "update"
  rescue StandardError => e
    logger.error("Controller:reference:update rescuing: #{e}")
    @message = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  # DELETE /references/1
  def destroy
    if @reference.update_attribute(:updated_by, username) && @reference.destroy
      render
    else
      render js: "alert('Could not delete that record.');"
    end
  end

  def copy
    reference = Reference.find(params[:id])
    @reference = Reference.new reference.attributes
    render :copy
  end

  # Columns such as duplicate_of_id use a typeahead search.
  def typeahead_on_citation
    render json: [] if params[:term].blank?
    render json: Reference::AsTypeahead::OnCitation.new(params[:term]).results
  end

  # Columns such as duplicate_of_id use a typeahead search.
  # ToDo: deprecate and get rid of route
  def typeahead_on_citation_with_exclusion
    render json: [] if params[:term].blank?
    render json: Reference::AsTypeahead::OnCitation.new(
      params[:term],
      params[:id]
    ).results
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  # ToDo: deprecate and get rid of route
  def typeahead_on_citation_duplicate_of_current
    render json: [] if params[:term].blank?
    render json: Reference::AsTypeahead::OnCitation.new(
      params[:term],
      params[:id]
    ).results
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def typeahead_on_citation_for_parent
    render json: [] if params[:term].blank?
    render json: Reference::AsTypeahead::OnCitationForParent.new(
      params[:term],
      params[:id],
      params[:ref_type_id]
    ).results
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def typeahead_on_citation_for_duplicate
    render json: [] if params[:term].blank?
    typeahead = Reference::AsTypeahead::OnCitationForDuplicate.new(
      params[:term],
      params[:id]
    )
    render json: typeahead.results
  end

  private

  def find_reference
    @reference = Reference.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the reference."
    redirect_to references_path
  end

  # NOTE: the order of the :year, :month, :day params is critical to
  # successfully processing these fields on insert and combining them into
  # the iso_publication_date field.
  def reference_params
    params.require(:reference)
          .permit(
            :abbrev_title, :bhl_url, :display_title, :doi, :edition, :isbn,
            :issn, :language_id, :notes, :pages, :publication_date, :published,
            :published_location, :publisher, :ref_author_role_id, :ref_type_id,
            :title, :tl2, :verbatim_author, :verbatim_citation,
            :verbatim_reference, :volume, :year, :month, :day
          )
  end

  def typeahead_params
    params.require(:reference).permit(:author_id, :author_typeahead,
                                      :duplicate_of_id, :duplicate_of_typeahead,
                                      :parent_id, :parent_typeahead)
  end

  def update_reference
    @reference = Reference::AsEdited.find(params[:id])
    @message = @reference.update_if_changed(reference_params,
                                            typeahead_params,
                                            current_user.username)
  end

  def copy_reference
    reference = @reference
    @reference = Reference.new reference.attributes
  end

  # Do this before getting to the model - much more control.
  def check_date_params
    raise "Month entered but no year" if reference_params[:year].blank? && !reference_params[:month].blank?
    return unless reference_params[:month].blank?
    raise "Day entered but no month" unless reference_params[:day].blank?
  end
end
