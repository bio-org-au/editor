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

#   Create a draft instance for a raw loader_name matched with a name record
class Loader::Name::DraftTaxonomyAdder::Preflights
  attr_reader :result_h

  def initialize(loader_name, draft, user, job)
    @loader_name = loader_name
    @draft = draft
    @user = user
    @job = job
    @task_start_time = Time.now
  end

  def check
    cleared = true
    case
    when @draft.blank?
      cleared = false
      preflight_error = "Please choose a draft version"
    when @loader_name.no_further_processing?
      cleared = false
      preflight_error = "no further processing"
    when @loader_name.preferred_match.blank?
      cleared = false
      preflight_error = "No preferred match"
    when @loader_name.preferred_match.blank? || 
         @loader_name.preferred_match.standalone_instance_id.blank?
      cleared = false
      preflight_error = "No instance identified"
    when @loader_name.preferred_match.drafted?
      cleared = false
      preflight_error = "Already on draft tree"
    when @loader_name.preferred_match.manually_drafted?
      cleared = false
      preflight_error = "Flagged as manually drafted"
    when @loader_name.parent.try("no_further_processing?")
      cleared = false
      preflight_error = "Parent excluded from further processing"
    end
    if cleared
      @result_h = {}
    else
      @result_h = {declines: 1, decline_reasons: {"#{preflight_error}": 1}}
      log_to_table("#{Constants::DECLINED} preflight check failed: " +
                   "for #{@loader_name.simple_name}, id: " +
                   "#{@loader_name.id}: " + "#{preflight_error}")
    end
    cleared
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)"
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
