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
class Loader::Name::MakeOneInstance
  def initialize(loader_name, authorising_user, job_number)
    debug("initialize; loader_name: #{loader_name}; job_number: #{job_number}")
    debug("authorising_user: #{authorising_user}")
    @loader_name = loader_name
    @authorising_user = authorising_user
    @job_number = job_number
    @task_start_time = Time.now
  end

  ###########################################################
  # Instance Case Options for "Accepted" Loader Names
  # (More complicated options than for Orchids, which were all new
  # entries)
  #
  # For "accepted" (aka top-level) loader_names only.
  # ie. these rules do NOT apply to synonyms or misapps.
  #
  # 1. use batch default reference to create a new draft instance and attach
  #    loader_name synonyms
  #
  # 2. use an existing instance (nothing to create)
  #
  # 3. copy and append: use batch default ref to create a new draft instance,
  #    attach loader_name synonyms and append the existing synonyms from the
  #    selected instance
  #
  # Data rules truth table
  # ======================
  #
  # case | loader_name_match           | loader_name_match               | batch default | loader_name_match
  #      | use_batch_default_reference | copy_append_from_existing_use_batch_def_ref | reference     | standalone_instance_id
  # -----|-------------------------------------------------------------------------------------------------------
  #  1.  | true                        | false                           | must exist    | should not exist
  #      |                             |                                 |               |
  #  2.  | false                       | false                           | n/a           | must exist
  #      |                             |                                 |               |
  #  3.  | true or false?              | true                            | must exist    | should not exist
  #      |                             |                                 |               |
  #

  def create
    return heading if @loader_name.heading?
    return no_further_processing if @loader_name.no_further_processing?

    if @loader_name.accepted? || @loader_name.excluded?
      create_standalone
    elsif @loader_name.synonym?
      create_synonymy
    elsif @loader_name.misapplied?
      create_misapp
    else
      throw "Don't know how to handle loader_name #{@loader_name.id}"
    end
  end

  def no_further_processing
    log_to_table("#{Constants::DECLINED_INSTANCE} - no further processing for #{@loader_name.id}")
    {declines: 1, decline_reasons: {no_further_processing: 1}}
  end

  def no_preferred_match
    log_to_table("#{Constants::DECLINED_INSTANCE} - no preferred match for ##{@loader_name.id} #{@loader_name.simple_name}")
    {declines: 1, decline_reasons: {no_preferred_match: 1}}
  end

  def heading
    log_to_table("#{Constants::DECLINED_INSTANCE} - heading entries not processed ##{@loader_name.id} #{@loader_name.simple_name}")
    {declines: 1, decline_reasons: {heading_so_not_processed: 1}}
  end

  def create_standalone
    return no_preferred_match unless @loader_name.preferred_match?

    MakeOneStandaloneInstance.new(@loader_name,
                                  @authorising_user,
                                  @job_number).create
  end

  def create_synonymy
    return no_preferred_match unless @loader_name.preferred_match?

    MakeOneSynonymyInstance.new(@loader_name,
                                @authorising_user,
                                @job_number).create
  end

  def create_misapp
    return no_preferred_match unless @loader_name.preferred_matches.size > 0

    result_h = {creates: 0, declines: 0, errors: 0}
    @loader_name.loader_name_matches.each do |misapp_match|
      Rails.logger.debug("candidate match: #{misapp_match.inspect}")
      result = MakeOneMisappInstance.new(@loader_name,
                                         misapp_match,
                                         @authorising_user,
                                         @job_number).create
      result_h.deep_merge!(result) { |key, old, new| old + new}
    end
    result_h
  end

  def log_create_action(count)
    entry = "Create instance counted #{count} #{'record'.pluralize(count)}"
    log_to_table(entry)
  end

  def log_to_table(payload)
    tag = " ##{@loader_name.id}, batch: #{@loader_name.batch.name},  " +
          "seq: #{@loader_name.seq} <b>#{@loader_name.simple_name}</b> " +
          " (#{@loader_name.record_type})"
    tag = "#{tag} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if @task_start_time
    payload = "#{payload} #{tag}"
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't save log to bulk processing log table: #{e}")
  end

  def scientific_name
    @loader_name.scientific_name
  end

  def record_failure(msg)
    msg.sub!("uncaught throw ", "")
    msg.gsub!('"', "")
    msg.sub!(/^Failing/, "")
    Rails.logger.error("Loader::Name::AsInstanceCreator failure: #{msg}")
    log_to_table("Loader::Name::AsInstanceCreator failure: #{msg}")
  end

  def debug(msg)
    Rails.logger.debug("Loader::Name::AsInstanceCreator #{msg} #{@tag}")
  end
end
