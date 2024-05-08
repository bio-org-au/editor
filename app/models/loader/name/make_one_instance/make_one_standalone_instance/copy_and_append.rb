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
class Loader::Name::MakeOneInstance::MakeOneStandaloneInstance::CopyAndAppend
  def initialize(loader_name, user, job)
    debug('initialize: #{loader_name.id}')
    @loader_name = loader_name
    @user = user
    @job = job
    @match = loader_name.preferred_match
    @task_start_time = Time.now
  end

  # ToDo: break into smaller parts
  def create
    debug("create")
    created = 0
    error_h = {errors: 0, error_reasons: {}}
    return no_def_ref if @loader_name.loader_batch.default_reference.blank?
    return no_source_for_copy if @match.source_for_copy.blank?

    create_the_standalone
    created += 1

    # # NOTE INSTANCE CREATED
    @match.standalone_instance_id = @new_standalone.id
    @match.standalone_instance_created = true
    @match.standalone_instance_found = false
    @match.updated_by = "@job for #{@user}"
    @match.save!

    syns_copied = 0
    @match.source_for_copy
          .synonyms
          .reject {|s| s.instance_type.unsourced}
          .reject {|s| s.instance_type.name == 'trade name'}
          .each do |source_synonym|
      new_syn = Instance.new
      new_syn.cites_id = source_synonym.cites_id
      new_syn.cited_by_id = @new_standalone.id
      new_syn.instance_type_id = source_synonym.instance_type_id
      new_syn.created_by = new_syn.updated_by = "bulk for #{@user}"
      new_syn.name_id = source_synonym.name_id
      new_syn.reference_id = @new_standalone.reference_id

      begin
        new_syn.save!
        syns_copied += 1
        log_to_table("#{Constants::COPIED_SYN} #{new_syn.name.full_name}")
      rescue StandardError => e
        error_h.deep_merge!({errors: 1, error_reasons: {e.to_s.to_sym => 1} }) { |key, old, new| old + new }
        log_to_table("#{Constants::FAILED_SYN} #{e} for #{new_syn.name.full_name}")
      end
    end
    error_h.deep_merge!({creates: created + syns_copied}) { |key, old, new| old + new }
  end

  def create_the_standalone
    debug("create_the_standalone")
    @new_standalone = Instance.new
    @new_standalone.draft = true
    @new_standalone.name_id = @match.name_id
    @new_standalone.reference_id = @loader_name.loader_batch.default_reference.id
    @new_standalone.instance_type_id = InstanceType.secondary_reference.id
    @new_standalone.created_by = @new_standalone.updated_by = "bulk for #{@user}"
    @new_standalone.save!
    log_to_table("#{Constants::CREATED_INSTANCE} #{@new_standalone.name.full_name}")
  end

  def no_def_ref
    log_to_table("#{Constants::DECLINED_INSTANCE} - no default reference " +
                 "for #{@loader_name.simple_name} #{@loader_name.id}", @user, @job)
    {declines: 1, decline_reasons: {no_default_ref: 1} }
  end

  def no_source_for_copy
    log_to_table("#{Constants::DECLINED_INSTANCE} - no source instance to " +
                 "copy #{@loader_name.simple_name} #{@loader_name.id}", @user, @job)
    {declines: 1, decline_reasons: {no_source_instance_to_copy: 1} }
  end

  def stand_already_noted
    log_to_table("#{Constants::DECLINED_INSTANCE} - standalone instance " +
                 "already noted for #{@loader_name.simple_name} " +
                 "#{@loader_name.id}")
    {declines: 1, decline_reasons: {standalone_instance_already_noted: 1} }
  end

  def stand_already_for_default_ref
    log_to_table("#{Constants::DECLINED_INSTANCE} - standalone instance " +
                 "exists for def ref for #{@loader_name.simple_name} " +
                 "#{@loader_name.id}")
    {declines: 1, decline_reasons: {standalone_instance_exists_for_default_ref: 1} }
  end

  def using_existing_instance
    log_to_table("#{Constants::DECLINED_INSTANCE} - using existing " +
                 " instance for #{@loader_name.simple_name} #{@loader_name.id}")
    {declines: 1, decline_reasons: {using_existing_instance: 1} }
  end

  def unknown_option
    log_to_table(
      "Error - unknown option for #{@loader_name.simple_name} #{@loader_name.id}"
    )
    log_error("Unknown option: ##{@match.id} #{@match.loader_name_id}")
    log_error("#{@match.inspect}")
    {errors: 1, error_reasons: {unknown_option: 1} }
  end

  def standalone_instance_already_noted?
    true unless @match.standalone_instance_id.blank?
  end

  def note_standalone_instance_created(instance)
    @match.standalone_instance_id = instance.id
    @match.standalone_instance_created = true
    @match.standalone_instance_found = false
    @match.updated_by = "job for #{@user}"
    @match.save!
    log_to_table("#{Constants::CREATED_INSTANCE} - standalone for " +
                 "##{@match.loader_name_id} #{@loader_name.simple_name}")
  end

  def note_standalone_instance(instance)
    Rails.logger.debug("note_standalone_instance")
    @match.standalone_instance_id = instance.id
    @match.standalone_instance_found = true
    @match.updated_by = "job for #{@user}"
    @match.save!
  end

  def debug(str)
    Rails.logger.debug("CopyAndAppend: #{str}")
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
