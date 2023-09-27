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

# Record a preferred matching name for a raw loader name record.
class Loader::Name::MakeOneMatch
  include Constants

  def initialize(loader_name, user, job)
    @tag = "#{self.class} for #{loader_name.simple_name} (#{loader_name.record_type})"
    @loader_name = loader_name
    @user = user
    @job = job
    @task_start_time = Time.now
  end

  def find_or_create_preferred_match
    return already_exists if preferred_match?
    return no_further_processing if @loader_name.no_further_processing?
    return misapp if @loader_name.misapplied?
    return heading if @loader_name.heading?
    return parent_using_existing if @loader_name.parent&.preferred_match&.use_existing_instance

    make_preferred_match?
  rescue StandardError => e
    Rails.logger.error("#{@tag}: #{e}")
    log_to_table("#{ERROR} - #{e}")
    COUNT_ERROR
  end

  def stop(msg)
    puts "Stopping because: #{msg}"
  end

  def preferred_match?
    !@loader_name.preferred_matches.empty?
  end

  def already_exists
    log_to_table("#{DECLINED} - existing")
    COUNT_DECLINED
  end

  def misapp
    log_to_table("#{DECLINED} - misapplications are not eligible")
    COUNT_DECLINED
  end

  def heading
    log_to_table("#{DECLINED} - headings don't get processed")
    COUNT_DECLINED
  end

  def no_further_processing
    log_to_table("#{DECLINED} - no further processing")
    COUNT_DECLINED
  end

  def parent_using_existing
    log_to_table("#{DECLINED} - parent is using an existing instance")
    COUNT_DECLINED
  end

  def make_preferred_match?
    if exactly_one_matching_name? &&
       matching_name_has_primary? &&
       matching_name_has_exactly_one_primary?
      create_match
      log_to_table(CREATED)
      COUNT_CREATED
    else
      log_to_table("#{DECLINED} - no single match found")
      COUNT_DECLINED
    end
  end

  def create_match
    pref = @loader_name.loader_name_matches.new
    pref.name_id = @loader_name.matches.first.id
    pref.instance_id = @loader_name.matches.first.primary_instances.first.id
    pref.relationship_instance_type_id = @loader_name.riti
    pref.created_by = pref.updated_by = "#{@user}"
    pref.save!
  end

  def exactly_one_matching_name?
    @loader_name.matches.size == 1
  end

  def matching_name_has_primary?
    !@loader_name.name_match_no_primary?
  end

  def matching_name_has_exactly_one_primary?
    @loader_name.matches.first.primary_instances.size == 1
  end

  def relationship_instance_type_id
    return nil if @loader_name.accepted?

    @loader_name.riti
  end

  def simple_name
    @loader_name.simple_name
  end

  def log_to_table(entry)
    tag = " ##{@loader_name.id}, batch: #{@loader_name.batch.name},  " +
          "seq: #{@loader_name.seq} <b>#{@loader_name.simple_name}</b> " +
          " (#{@loader_name.record_type})"
    tag = "#{tag} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    payload = "#{entry} #{tag}"
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end

  def debug(msg)
    Rails.logger.debug("${@tag}: #{msg}")
  end
end
