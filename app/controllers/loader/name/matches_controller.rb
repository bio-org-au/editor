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
class Loader::Name::MatchesController < ApplicationController
  before_action :find_loader_name, only: [:set]
  before_action :find_loader_name_match, only: [:update]
  #before_action :find_loader_name_match, only: [:delete]

  # For a given loader_name record, a set action may involve
  # a create or a delete or no change because user has radio
  # buttons to add or remove a match record.
  # This is for 'accepted' records or synonyms, where only 
  # one match is allower per loader-name.
  def set
    apply_changes
    render
   rescue => e
     logger.error("Loader::Name::Matches#create rescuing #{e}")
     @message = e.to_s
     render "create_error", status: :unprocessable_entity
  end

  def delete_all
    saved_matches = Loader::Name::Match.where(loader_name_id: params[:id])
    raise "no record for params[:id]: #{params[:id]}" if saved_matches.empty?
    saved_matches.each do |match|
      match.delete
    end
  end

  # For misapplications
  def create_or_delete
    @loader_name = Loader::Name.find(params[:id])
    Rails.logger.debug("@loader_name: #{@loader_name.id}")
    if params[:commit] == 'Remove'
      delete
    else
      create_preferred_match2
    end
  end

  def delete
    @loader_name_match = Loader::Name::Match.where(loader_name_id: loader_name_match_params[:loader_name_id])
      .where(name_id: loader_name_match_params[:name_id])
      .where(instance_id: loader_name_match_params[:instance_id]).first
    @instance_id = loader_name_match_params[:instance_id]
    @loader_name_match.delete
    render :delete_for_misapp
  end

  def update
    case params[:commit] 
    when nil
      raise 'no commit param'
    when /flag.* manually drafted/i
      flag_as_manually_drafted
    when /remove.*manually.drafted.flag/i
      unflag_as_manually_drafted
    else
      update_relationship_instance_type
    end
  rescue => e
    logger.error("Loader::Name::MatchesController error: #{e.to_s}")
    @message = e.to_s
    render 'update_error', format: :js
  end

  private
  def find_loader_name
    @loader_name = Loader::Name.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the loader name record."
    redirect_to loader_names_path
  end

  def find_loader_name_match
    @loader_name_match = Loader::Name::Match.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the loader name match record."
    redirect_to loader_name_matches_path
  end

  def apply_changes
    Rails.logger.debug('apply_changes')
    @loader_name_matches = Loader::Name::Match.where(loader_name_id: @loader_name.id)
    stop_if_nothing_changed
    return 'No change' if params[:loader_name].blank? 

    remove_unwanted_loader_names_matches
    create_preferred_match
  end

  # Doesn't handle multiple name_ids being passed in params
  def remove_unwanted_loader_names_matches
    return if @loader_name_matches.blank? 
    @loader_name_matches.each do |match|
      unless loader_name_params[:name_id] == match[:name_id]
        match.delete
      end
    end
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
    raise 'no change required' unless changed
  end

  def create_preferred_match
    loader_name_match = ::Loader::Name::Match.new
    loader_name_match.loader_name_id = @loader_name.id
    loader_name_match.name_id = loader_name_params[:name_id]
    loader_name_match.instance_id = loader_name_params[:instance_id] || ::Name.find(loader_name_params[:name_id]).primary_instances.first.id
    loader_name_match.relationship_instance_type_id = @loader_name.riti
    loader_name_match.created_by = loader_name_match.updated_by = username
    loader_name_match.save!
    'Saved'
  end

  
  def create_preferred_match2
    loader_name_match = ::Loader::Name::Match.new
    loader_name_match.loader_name_id = @loader_name.id
    loader_name_match.name_id = loader_name_match_params[:name_id]
    loader_name_match.instance_id = loader_name_match_params[:instance_id] || ::Name.find(loader_name_match_params[:name_id]).primary_instances.first.id
    loader_name_match.relationship_instance_type_id = @loader_name.riti
    loader_name_match.created_by = loader_name_match.updated_by = username
    loader_name_match.save!
    @instance_id = loader_name_match_params[:instance_id]
    render :create_for_misapp
  end

  def flag_as_manually_drafted
    if @loader_name_match.manually_drafted?
      raise 'no change required'
    else
      @loader_name_match.manually_drafted = true
      @loader_name_match.save!
    end
  end

  def unflag_as_manually_drafted
    if @loader_name_match.manually_drafted?
      @loader_name_match.manually_drafted = false
      @loader_name_match.save!
    else
      raise 'no change required'
    end
  end

  def update_relationship_instance_type
    raise "No change!" if @loader_name_match.relationship_instance_type_id == loader_name_match_params[:relationship_instance_type_id].to_i
    @loader_name_match.relationship_instance_type_id = loader_name_match_params[:relationship_instance_type_id]
    @loader_name_match.updated_by = username
    @loader_name_match.save!
  rescue => e
    logger.error(e.to_s)
    @message = e.to_s
    render 'update_error', format: :js
  end

  # In this controller because some loader_name_match actions originate from 
  # a loader_name record
  def loader_name_params
    params.require(:loader_name).permit(:simple_name, :name_id, :instance_id,
                                        :record_type, :parent, :parent_id, 
                                        :name_status, :ex_base_author,
                                        :base_author, :ex_author, :author,
                                        :synonym_type, :comment, :seq,
                                        :doubtful,
                                        :no_further_processing, :notes,
                                        :distribution, :loader_name_id)
  end

  def loader_name_match_params
    params.require(:loader_name_match).permit(:name_id, :instance_id,
                                              :loader_name_id,
                                             :relationship_instance_type_id)
  end
end
