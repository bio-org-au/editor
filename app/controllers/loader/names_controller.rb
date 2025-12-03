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
  include Loader::Names::ParentTypeahead
  before_action :find_loader_name,
                only: %i[show destroy tab update set_preferred_match]
  before_action :find_loader_name_including_matches,
                only: %i[force_destroy]

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @current_families = current_families if @tab == 'tab_edit'
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
    @loader_name.family = @anchor.family unless @anchor.blank?
    @current_families = current_families
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    render :new
  end

  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    render :new_row, 
           locals: {partial: 'new_row', 
                    locals_for_partial:
               {tab_path: "#{loader_name_new_with_random_id_path(@random_id)}",
                link_id: "link-new-loader-name-#{@random_id}",
                link_title: "New loader name accepted or excluded record.",
                link_text: "New Accepted or Excluded Loader Name"
               }
                   }
  end

  def new_heading_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    render :new_row, 
           locals: {partial: 'new_row', 
                    locals_for_partial:
               {tab_path: "#{loader_name_heading_new_with_random_id_path(@random_id)}",
                link_id: "link-new-loader-name-#{@random_id}",
                link_title: "New loader name heading record.",
                link_text: "New Loader Name Heading"
               }
                   }
  end

  def new_in_batch_note_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    render :new_row, 
           locals: {partial: 'new_row', 
                    locals_for_partial:
               {tab_path: "#{loader_name_in_batch_note_new_with_random_id_path(@random_id)}",
                link_id: "link-new-loader-name-#{@random_id}",
                link_title: "New loader name in-batch-note record.",
                link_text: "New Loader Name In-Batch-Note"
               }
                   }
  end

  def new_heading
    @loader_name = ::Loader::Name.new
    @loader_name.simple_name = nil
    @loader_name.full_name = nil
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    @loader_name.record_type = "heading"
    render :new_heading
  end

  def new_in_batch_note
    @loader_name = ::Loader::Name.new
    @loader_name.simple_name = @loader_name.full_name = nil
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    @loader_name.record_type = "in-batch-note"
    render :new_in_batch_note
  end

  def new_row_here
    @random_id = (Random.new.rand * 10_000_000_000).to_i
  end

  def update
    work_out_parent_from_typeahead
    @message = @loader_name.update_if_changed(loader_name_params
      .reject {|p| p.match(/parent_typeahead/)}, current_user.username)
    render "update"
  rescue StandardError => e
    logger.error("Loader::Names#update rescuing #{e}")
    @message = e.to_s
    render "update_error", status: :unprocessable_content
  end

  # For a given loader_name record, add or remove a loader_name_match
  # record confirming the chosen name record for the match
  def set_preferred_match
    @message = update_matches
    render
  rescue StandardError => e
    logger.error("Loader::Names#set_preferred_match rescuing #{e}")
    @message = e.to_s
    render "set_preferred_match_error", status: :unprocessable_content
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

  # Note: this is (too) complicated
  # The reason is it complicated: it is handling creates coming from 
  # simple actions in the loader interface, but it's also handling
  # creates from over in apni data.
  def create
    insist_on_a_batch unless params["form-task"] == "supplement-existing-concept"
    if loader_name_params["loaded_from_instance_id"].blank?
      @loader_name = Loader::Name.create(loader_name_params, current_user.username)
    else 
      create_when_loaded_from_existing_instance
    end 
    render "create"
  rescue StandardError => e
    logger.error("Controller:Loader::Names:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_content
  end

  def destroy
    @loader_name.delete
  rescue StandardError => e
    logger.error("Loader::NamesController#destroy rescuing #{e}")
    @message = e.to_s
    render "destroy_error", status: :unprocessable_content
  end

  def force_destroy
    @destroyed_ids = @loader_name.force_delete
  rescue StandardError => e
    logger.error("Loader::NamesController#force_destroy rescuing #{e}")
    @message = e.to_s
    render "destroy_error", status: :unprocessable_content
  end


  def create_heading
    Loader::Name.create_family_heading(params) 
    @message = 'Created - the record will be available next time you query the family'
  rescue StandardError => e
    logger.error("Loader::NamesController#create_heading rescuing #{e}")
    @message = e.to_s
    render "create_heading_error", status: :unprocessable_content
  end
  #############################################################################
  private

  def find_loader_name
    @loader_name = Loader::Name.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the loader name record."
    redirect_to loader_names_path
  end

  def find_loader_name_including_matches
    @loader_name = Loader::Name.includes([:loader_name_matches]).where(id: params[:id]).first
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the loader name record."
    redirect_to loader_names_path
  end

  def insist_on_a_batch
    if session[:default_loader_batch_name].blank? && 
        loader_name_params[:loader_batch_id].blank?
      raise "Please set a default batch"
    end
  end 

  # This is for creates started over in the Name records.
  # It has more complicated requirements than a simple create inside the loader.
  def create_when_loaded_from_existing_instance
    ActiveRecord::Base.transaction do
      if params["form-task"] == "supplement-existing-concept"
        @loader_name = Loader::Name.find(embedded_parent_typeahead_id(loader_name_params[:parent_typeahead]))
      else
        @loader_name = Loader::Name.create(loader_name_params, current_user.username)
          @loader_name.create_match_to_loaded_from_instance_name(current_user.username)
      end

      if params["form-task"] == "supplement-existing-concept"
        main_supplement = @loader_name.create_flipped_synonym_for_instance(loader_name_params, @current_user)
      end
      if loader_name_params["add_sibling_synonyms"] == 'true'
        siblings = @loader_name.create_sibling_synonyms_for_instance(loader_name_params["loaded_from_instance_id"], @current_user)
      end
      if loader_name_params["add_sourced_synonyms"] == 'true'
        siblings = @loader_name.create_sourced_synonyms_for_instance(loader_name_params[:loaded_from_instance_id],
                                                                     loader_name_params[:remark_to_reviewers], @current_user)
      end
    end
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
                                        :loaded_from_instance_id,
                                        :add_sibling_synonyms,
                                        :add_sourced_synonyms,
                                        :original_text,
                                        :parent_typeahead,
                                        :formatted_text_above,
                                        :formatted_text_below,)
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
      batch_review_period_id: period.id
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

  def embedded_parent_typeahead_id(typeahead_value)
    raise ArgumentError, "Input too long" if typeahead_value.length > 1000
    typeahead_value.sub(/.*\(/,'').sub(/\).*/,'') 
  end

  def current_families
    if session[:default_loader_batch_id].blank?
      []
    else
      current_batch = Loader::Batch.find(session[:default_loader_batch_id])
      current_batch.families
    end
  end
end
