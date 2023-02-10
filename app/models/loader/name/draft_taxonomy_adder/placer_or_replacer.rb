# frozen_string_literal: true
#  Copyright 2015 Australian National Botanic Gardens
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

#   Place or replace instance in draft taxonomy
class Loader::Name::DraftTaxonomyAdder::PlacerOrReplacer
  attr_reader :added, :declined, :errors, :result
  
  def initialize(loader_name, draft, user, job)
    @loader_name = loader_name
    @draft = draft
    @user = user
    @job = job
    @added = @declined = @errors = 0
    @result = false
  end


  # From @loader_name work out the name and instance you're interested in.
  # 
  # for all the preferred names/instances of the loader name
  # loop
  #   if the name is on the draft
  #     replace it
  #   else
  #     place it
  #   end
  # end
  def place_or_replace
    @loader_name.preferred_matches.each do |preferred_match|
      if preferred_match.standalone_instance_id.blank?
        debug "No instance, therefore cannot place this on the Taxonomy."
      elsif preferred_match.drafted?
        debug "Stopping because already drafted."
      else
        @tree_version_element = @draft.name_in_version(preferred_match.name)
        if @tree_version_element.present?
          debug 'name is on the draft: replace it'
          return replace_name(preferred_match)
        else
          debug 'name is not on the draft: just place it'
          place_name(preferred_match)
        end
      end
    end
  rescue RestClient::ExceptionWithResponse => e
    @placed_count = 0
    @errors = 1
    @error = json_error(e)
    log_to_table("Error placing or replacing on taxonomy: #{@loader_name.simple_name}, id: #{@loader_name.id}: #{@error}")
    #if inferred_rank.downcase == 'genus'
      #raise GenusTaxonomyPlacementError.new("Stopping because failed to add genus #{@loader_name.simple_name}")
    #else
      #0
    #end
  rescue => e
    Rails.logger.error("PlaceOrReplace: Error placing or replacing loader_name on taxonomy #{e.message}")
    log_to_table("Error placing/replacing on taxonomy: #{@loader_name.simple_name}, id: #{@loader_name.id}: #{e.message}")
  end

  def counts
    [@added, @declined, @errors]
  end

  private

  def debug(msg)
    Rails.logger.debug("Loader::Name::DraftTaxonomyAdder::PlaceOrReplace: #{msg}")
  end

  def place_name(preferred_match)
    placer = Placer.new(preferred_match, @draft, @user, @job)
    placer.place
    @added, @declined, @errors, @result = placer.status
  end

  def replace_name(preferred_match)
    replacer = Replacer.new(preferred_match, @draft, @tree_version_element, @user, @job)
    replacer.replace
    @added, @declined, @errors, @result = replacer.status
  end

  def json_error(err)
    json = JSON.parse(err.http_body, object_class: OpenStruct)
    if json&.error
      json.error
    else
      json&.to_s || err.to_s
    end
  rescue
    err.to_s
  end

  def inferred_rank
    (@loader_name.rank_nsl ||
     @loader_name.rank ||
     @loader_name&.preferred_matches&.first&.name&.name_rank&.name ||
     'cannot infer rank')
  end

  def log_to_table(payload)
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end
end