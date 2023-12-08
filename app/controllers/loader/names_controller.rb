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
class Loader::NamesController < ApplicationController
  before_action :find_loader_name,
                only: %i[show destroy tab update set_preferred_match]

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == "true"
    new_comment if params[:tab] == "tab_review"
    if @view_mode == ::ViewMode::REVIEW
      render "loader/names/review/show", layout: false
    else
      render "show", layout: false
    end
  end

  alias tab show

  def new
    @anchor = Loader::Name.find(params[:loader_name_id]) unless params[:loader_name_id].blank?
    @loader_name = ::Loader::Name.new
    @loader_name.simple_name = @loader_name.full_name = nil
    @loader_name.record_type = "accepted"
    @loader_name.rank = "species"
    @loader_name.seq = @anchor.seq + 1 unless @anchor.blank?
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  def new_heading
    @loader_name = ::Loader::Name.new
    @loader_name.simple_name = nil
    @loader_name.full_name = nil
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    @loader_name.record_type = "heading"
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new_in_batch_note
    @loader_name = ::Loader::Name.new
    @loader_name.simple_name = @loader_name.full_name = nil
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    @loader_name.record_type = "in-batch-note"
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new_heading_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  def new_in_batch_note_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  def new_row_here
    @random_id = (Random.new.rand * 10_000_000_000).to_i
  end

  def update
    @message = @loader_name.update_if_changed(loader_name_params,
                                              current_user.username)
    render "update"
  rescue StandardError => e
    logger.error("Loader::Names#update rescuing #{e}")
    @message = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  # For a given loader_name record, add or remove a loader_name_match
  # record confirming the chosen name record for the match
  def set_preferred_match
    @message = update_matches
    render
  rescue StandardError => e
    logger.error("Loader::Names#set_preferred_match rescuing #{e}")
    @message = e.to_s
    render "set_preferred_match_error", status: :unprocessable_entity
  end

  def update_matches
    Rails.logger.debug("update_matches")
    @loader_name_matches = Loader::Name::Match.where(loader_name_id: @loader_name.id)
    stop_if_nothing_changed
    return "No change" if params[:loader_name].blank?

    create_preferred_match unless clearing_all_preferred_matches?
  end

  def stop_if_nothing_changed
    return if @loader_name_matches.blank?

    changed = false
    @loader_name_matches.each do |loader_name_match|
      unless loader_name_match.name_id == loader_name_params[:name_id].to_i &&
             loader_name_match.instance_id == loader_name_params[:instance_id]
        changed = true
      end
    end
    raise "no change required" unless changed
  end

  def create_preferred_match
    loader_name_match = ::Loader::Name::Match.new
    loader_name_match.loader_name_id = @loader_name.id
    loader_name_match.name_id = loader_name_params[:name_id]
    loader_name_match.instance_id = loader_name_params[:instance_id] || Name.find(loader_name_params[:name_id]).primary_instances.first.id
    loader_name_match.relationship_instance_type_id = @loader_name.riti
    loader_name_match.created_by = loader_name_match.updated_by = username
    loader_name_match.save!
  end

  # The clear form sends a name_id of -1
  # The aim of clear is to remove all chosen matches
  # i.e. don't set a preferred match
  def clearing_all_preferred_matches?
    false # orc hid_params[:name_id].to_i < 0
  end

  def parent_suggestions
    typeahead = Loader::Name::AsTypeahead::ForParent.new(params)
    render json: typeahead.suggestions
  end

  def create
    if session[:default_loader_batch_name].blank? && 
        loader_name_params[:loader_batch_id].blank?
      raise "Please set a default batch"
    end

    @loader_name = Loader::Name.create(loader_name_params, current_user.username)
    unless loader_name_params["loaded_from_instance_id"].blank?
      @loader_name.create_match_to_loaded_from_instance_name(current_user.username)
    end

    render "create"
  rescue StandardError => e
    logger.error("Controller:Loader::Names:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_entity
  end

  def destroy
    @loader_name.delete
  rescue StandardError => e
    logger.error("Loader::NamesController#destroy rescuing #{e}")
    @message = e.to_s
    render "destroy_error", status: :unprocessable_entity
  end

  #############################################################################
  private

  def find_loader_name
    @loader_name = Loader::Name.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the loader name record."
    redirect_to loader_names_path
  end

  def loader_name_params
    params.require(:loader_name).permit(:simple_name, :full_name, :name_id,
                                        :instance_id, :record_type, :parent,
                                        :parent_id, :name_status,
                                        :ex_base_author, :base_author,
                                        :ex_author, :author,
                                        :synonym_type, :comment, :seq,
                                        :doubtful, :family, :excluded,
                                        :no_further_processing, :notes,
                                        :distribution, :loader_batch_id,
                                        :rank, :remark_to_reviewers, :sort_key,
                                        :loaded_from_instance_id)
  end

  def set_tab
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             "tab_details"
           end
  end

  def set_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end

  def new_comment
    return unless reviewer?

    @name_review_comment = @loader_name.name_review_comments.new(
      batch_reviewer_id: reviewer.id,
      loader_name_id: @loader_name.id,
      review_period_id: period.id
    )
  end

  # TODO: handle multiple periods, including active and inactive
  def period
    @loader_name.batch.reviews&.first&.periods&.first
  end

  # TODO: handle multiple periods, including active and inactive
  def reviewer?
    @loader_name.batch.reviews&.first&.periods&.first&.reviewers&.collect do |x|
      x.user.userid
    end&.include?(@current_user.username)
  end

  # TODO: handle multiple periods, including active and inactive
  def reviewer
    @loader_name.batch.reviews&.first&.periods&.first&.reviewers&.select do |x|
      x.user.userid == @current_user.username
    end&.first
  end
end
