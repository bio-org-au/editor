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

# Save a preferred matching name for a raw orchid record.
class Orchid::AsNameMatcher
  def initialize(orchid, authorising_user)
    debug("Name matcher for orchid: #{orchid.taxon} (#{orchid.true_record_type})")
    @orchid = orchid
    @authorising_user = authorising_user
    @log_tag = " for #{@orchid.id}, seq: #{@orchid.seq} #{@orchid.taxon} (#{@orchid.true_record_type})"
  end

  def find_or_create_preferred_match
    if preferred_match?
      0
    elsif @orchid.exclude_from_further_processing? ||
          @orchid.parent.try("exclude_from_further_processing?")
      0
    elsif @orchid.misapplied?
      0
    elsif make_preferred_match?
      1
    else
      0
    end
  rescue StandardError => e
    Rails.logger.error(e.to_s)
    log_to_table("Error: preferred match problem for #{@orchid.id}, seq: #{@orchid.seq} #{@orchid.taxon} - #{e}")
    0
  end

  def stop(msg)
    puts "Stopping because: #{msg}"
  end

  def preferred_match?
    !@orchid.preferred_match.empty?
  end

  def make_preferred_match?
    if exactly_one_matching_name? &&
       matching_name_has_primary? &&
       matching_name_has_exactly_one_primary?
      create_match
      true
    else
      log_to_table("Make preferred match problem: #{non_creation_reason}")
      false
    end
  end

  def non_creation_reason
    if exactly_one_matching_name?
      reason += "matching names's instance is not primary; " unless matching_name_has_primary?
      reason += "matching names has more than one primary instance; " unless matching_name_has_exactly_one_primary?
      reason = "Unknown reason" if reason.blank?
    else
      reason = "#{@orchid.matches.size} matching names"
    end
  rescue StandardError => e
    Rails.logger.error(e.to_s)
    reason = "couldn't determine reason"
  end

  def create_match
    log_to_table("Make preferred match")
    pref = @orchid.orchids_name.new
    pref.name_id = @orchid.matches.first.id
    pref.instance_id = @orchid.matches.first.primary_instances.first.id
    pref.relationship_instance_type_id = @orchid.riti
    pref.created_by = pref.updated_by = "#{@authorising_user}"
    pref.save!
  end

  def log_to_table(entry)
    OrchidProcessingLog.log("#{entry} #{@log_tag}", @authorising_user)
  rescue StandardError => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end

  def exactly_one_matching_name?
    @orchid.matches.size == 1
  end

  def matching_name_has_primary?
    !@orchid.name_match_no_primary?
  end

  def matching_name_has_exactly_one_primary?
    @orchid.matches.first.primary_instances.size == 1
  end

  def relationship_instance_type_id
    return nil if @orchid.accepted?

    @orchid.riti
  end

  def taxon
    @orchid.taxon
  end

  def debug(msg)
    Rails.logger.debug("#{msg}")
  end
end
