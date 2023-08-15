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
class OrchidsController < ApplicationController
  before_action :find_orchid, only: %i[show update tab destroy]

  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  alias tab show

  def update
    logger.debug("OrchidsController#update")
    if orchid_params.blank?
      @message = "No change"
      render "update_no_change"
    elsif orchid_params[:name_id].blank?
      update_the_raw_record
    else
      update_matching_name
    end
  rescue StandardError => e
    logger.error("OrchidsController#update: #{e}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s
    render "update_error", format: :js
  end

  def update_matching_name
    @orchids_names = OrchidsName.where(orchid_id: @orchid.id)
    stop_if_nothing_changed
    remove_unwanted_orchid_names
    set_a_preferred_match unless clearing_all_preferred_matches?
  end

  # The clear form sends a name_id of -1
  # The aim of clear is to remove all chosen matches
  # i.e. don't set a preferred match
  def clearing_all_preferred_matches?
    orchid_params[:name_id].to_i < 0
  end

  def set_a_preferred_match
    orchids_name = OrchidsName.new
    orchids_name.orchid_id = @orchid.id
    orchids_name.name_id = orchid_params[:name_id]
    orchids_name.instance_id = orchid_params[:instance_id] || Name.find(orchid_params[:name_id]).primary_instances.first.id
    orchids_name.relationship_instance_type_id = @orchid.riti
    orchids_name.created_by = orchids_name.updated_by = username
    orchids_name.save!
  end

  def update_the_raw_record
    @orchid = Orchid.find(params[:id])
    @message = @orchid.update_if_changed(orchid_params, current_user.username)
    render "update"
  rescue StandardError => e
    logger.error("Orchid#update_the_raw_record rescuing #{e}")
    @message = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  def destroy
    @orchid.delete
  rescue StandardError => e
    logger.error("Orchid#destroy rescuing #{e}")
    @message = e.to_s
    render "destroy_error", status: :unprocessable_entity
  end

  # GET /orchids/new_row
  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  # GET /orchids/new
  def new
    @orchid = Orchid.new
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  # POST /orchids
  def create
    @orchid = Orchid.create(orchid_params, current_user.username)
    render "create"
  rescue StandardError => e
    logger.error("Controller:Authors:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_entity
  end # For the typeahead search.

  def parent_suggestions
    typeahead = Orchid::AsTypeahead::ForParent.new(params)
    render json: typeahead.suggestions
  end

  private

  def find_orchid
    @orchid = Orchid.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the orchid."
    redirect_to orchids_path
  end

  def orchid_params
    return nil if params[:orchid].blank?

    params.require(:orchid).permit(:taxon, :name_id, :instance_id,
                                   :record_type, :parent, :parent_id,
                                   :name_status, :ex_base_author,
                                   :base_author, :ex_author, :author,
                                   :synonym_type, :comment, :seq,
                                   :alt_taxon_for_matching, :doubtful,
                                   :exclude_from_further_processing, :notes,
                                   :distribution)
  end

  def set_tab
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             "tab_show_1"
           end
  end

  def set_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end

  def stop_if_nothing_changed
    return if @orchids_names.blank?

    changed = false
    @orchids_names.each do |orchid_name|
      unless orchid_name.name_id == orchid_params[:name_id].to_i &&
             orchid_name.instance_id == orchid_params[:instance_id]
        changed = true
      end
    end
    raise "no change required" unless changed
  end

  # Doesn't handle multiple name_ids being passed in params
  def remove_unwanted_orchid_names
    return if @orchids_names.blank?

    @orchids_names.each do |orchid_name|
      unless orchid_name.name_id == orchid_params[:name_id].to_i &&
             orchid_name.instance_id == orchid_params[:instance_id].to_i
        orchid_name.delete
      end
    end
  end
end
