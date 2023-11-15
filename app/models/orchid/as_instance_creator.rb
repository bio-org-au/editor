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

#   Create a draft instance for a raw orchid matched with a name record
class Orchid::AsInstanceCreator
  def initialize(orchid, reference, authorising_user)
    @tag = " for orchid: #{orchid.id}, seq: #{orchid.seq} #{orchid.taxon} (#{orchid.true_record_type})"
    debug("AsInstanceCreator")
    @orchid = orchid
    @ref = reference
    @authorising_user = authorising_user
  end

  def create
    return 0 if stop_everything?

    @created = 0
    @errors = 0
    @orchid.preferred_match.each do |preferred_match|
      @created += preferred_match.create_instance(@ref, @authorising_user)
      log_create_action(@created)
    rescue StandardError => e
      @errors += 1
      log_to_table("Errors creating instance for preferred match #{preferred_match.id} - #{e.message}")
    end
  end

  attr_reader :created, :errors

  def log_create_action(count)
    entry = "Create instance counted #{count} #{'record'.pluralize(count)}"
    log_to_table(entry)
  end

  def log_to_table(entry)
    OrchidProcessingLog.log("#{entry} #{@tag}", @authorising_user)
  rescue StandardError => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end

  def stop_everything?
    if @orchid.exclude_from_further_processing?
      return true
    elsif @orchid.parent.try("exclude_from_further_processing?")
      return true
    elsif @orchid.hybrid_cross?
      debug("stop_everything?  Orchid is a hybrid cross - not going to process these.")
      return true
    end

    false
  end

  def taxon
    @orchid.taxon
  end

  def record_failure(msg)
    msg.sub!("uncaught throw ", "")
    msg.gsub!('"', "")
    msg.sub!(/^Failing/, "")
    Rails.logger.error("Orchid::AsInstanceCreator failure: #{msg}")
    log_to_table("Orchid::AsInstanceCreator failure: #{msg}")
  end

  def debug(msg)
    Rails.logger.debug("Orchid::AsInstanceCreator #{msg} #{@tag}")
  end
end
