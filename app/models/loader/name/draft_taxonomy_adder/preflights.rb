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
  attr_reader :added, :declined, :errors, :clear
  
  def initialize(loader_name, draft, user, job)
    @loader_name = loader_name
    @draft = draft
    @user = user
    @job = job
  end

  def check
    case 
    when @draft.blank?
      stop = true
      preflight_error = "Please choose a draft version"
    when @loader_name.no_further_processing?
      stop = true
      preflight_error = "no further processing"
    when @loader_name.preferred_match.blank?
      stop = true
      preflight_error = "No preferred matching name for #{@loader_name.simple_name}"
    when @loader_name.preferred_match.blank? || @loader_name.preferred_match.standalone_instance_id.blank?
      stop = true
      preflight_error = "No instance identified for #{@loader_name.simple_name}"
    when @loader_name.preferred_match.drafted?
      stop = true
      preflight_error = "Stopping because #{@loader_name.simple_name} is already on the draft tree"
    when @loader_name.preferred_match.manually_drafted?
      stop = true
      preflight_error = "Stopping because #{@loader_name.simple_name} is flagged as manually drafted"
    when @loader_name.parent.try('no_further_processing?')
      stop = true
      preflight_error = "Parent of #{@loader_name.simple_name} is excluded from further processing"
    end
    if stop
      @clear = false
      @preflight_stop_count = 1
      log_to_table("#{Constants::DECLINED} preflight check prevented adding to draft: #{@loader_name.simple_name}, id: #{@loader_name.id}, seq: #{@loader_name.seq}: #{preflight_error}")
    else
      @clear = true
    end
  end

  def log_to_table(payload)
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end

end

