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
  attr_reader :result, :result_h

  def initialize(loader_name, draft, user, job)
    @loader_name = loader_name
    @draft = draft
    @user = user
    @job = job
    @result = false
    @task_start_time = Time.now
    @result_h = {}
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
      elsif @draft.name_in_version(preferred_match.name.parent).blank?
        raise "No parent on tree, cannot proceed"
      else
        @tree_version_element = @draft.name_in_version(preferred_match.name)
        if @tree_version_element.present?
          debug "name is on the draft: replace it"
          return replace_name(preferred_match)
        else
          debug "name is not on the draft: just place it"
          place_name(preferred_match)
        end
      end
    end
  rescue RestClient::ExceptionWithResponse => e
    e_to_s = json_error(e)
    @result_h = {errors: 1, error_reasons: {"#{e_to_s}": 1}}
    log_to_table("<span class='red'>Error from Services placing/replacing on taxonomy:</span> #{@loader_name.simple_name}, ##{@loader_name.id}: #{e_to_s}")
  rescue StandardError => e
    @result_h = {errors: 1, error_reasons: {"#{e.to_s}": 1}}
    log_to_table("<span class='red'>Error placing/replacing on taxonomy:</span> #{@loader_name.simple_name}, ##{@loader_name.id}: #{e.message}")
  end

  private

  def debug(msg)
    Rails.logger.debug("Loader::Name::DraftTaxonomyAdder::PlaceOrReplace: #{msg}")
  end

  def place_name(preferred_match)
    placer = Placer.new(preferred_match, @draft, @user, @job)
    placer.place
    @result_h = placer.result_h
  end

  def replace_name(preferred_match)
    replacer = Replacer.new(preferred_match, @draft, @tree_version_element, @user, @job)
    replacer.replace
    @result_h = replacer.result_h
  end

  def json_error(err)
    json = JSON.parse(err.http_body, object_class: OpenStruct)
    if json&.error
      json.error
    else
      json&.to_s || err.to_s
    end
  rescue StandardError
    err.to_s
  end

  def xinferred_rank
    (@loader_name.rank_nsl ||
     @loader_name.rank ||
     @loader_name&.preferred_matches&.first&.name&.name_rank&.name ||
     "cannot infer rank")
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("PlaceOrReplace couldn't log to log table: #{e}")
  end
end
