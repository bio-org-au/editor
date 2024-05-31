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
class Loader::Name::MakeOneInstance::MakeOneStandaloneInstance
  def initialize(loader_name, user, job)
    @tag = "#{self.class} for #{loader_name.simple_name} (#{loader_name.record_type})"
    @loader_name = loader_name
    @user = user
    @job = job
    @match = loader_name.preferred_match
    @task_start_time = Time.now
  end

  def create
    return using_existing_instance if using_existing_instance?
    return stand_already_noted if standalone_instance_already_noted?
    return no_default_ref if no_default_ref?
    return stand_already_for_default_ref if standalone_instance_for_default_ref?

    if @match.instance_choice_confirmed == false
      @match.use_batch_default_reference = true
      @match.instance_choice_confirmed = true
      @match.save!
      create_using_default_ref
    elsif @match.use_batch_default_reference == true
      create_using_default_ref
    elsif @match.copy_append_from_existing_use_batch_def_ref == true
      copy_and_append
    else
      unknown_option
    end
  end

  def create_using_default_ref
    UseDefaultRef.new(@loader_name, @user, @job).create
  end

  def copy_and_append
    CopyAndAppend.new(@loader_name, @user, @job).create
  end

  def using_existing_instance?
    @match.use_existing_instance == true
  end

  def using_existing_instance
    log_to_table("#{Constants::DECLINED_INSTANCE} - using existing " +
                 " instance for #{@loader_name.simple_name} #{@loader_name.id}")
    {declines: 1, declines_reasons: {using_existing_instance: 1}}
  end

  def stand_already_noted
    log_to_table("#{Constants::DECLINED_INSTANCE} - standalone instance " +
                 "already noted for #{@loader_name.simple_name} " +
                 "#{@loader_name.id}")
    {declines: 1, declines_reasons: {standalone_instance_already_noted: 1}}
  end

  def find_standalone_instances_for_default_ref
    Instance.where(name_id: @match.name_id)
            .where(reference_id:
                    @loader_name.loader_batch.default_reference.id)
            .joins(:instance_type)
            .where(instance_type: { standalone: true })
  end

  def standalone_instance_for_default_ref?
    instances = find_standalone_instances_for_default_ref
    case instances.size
    when 0
      false
    when 1
      @match.note_standalone_instance_found(instances.first)
      true
    else
      throw "Unexpected 2+ standalone instances"
    end
  end

  def stand_already_for_default_ref
    log_to_table("#{Constants::DECLINED_INSTANCE} - standalone instance " +
                 "exists for def ref for #{@loader_name.simple_name} " +
                 "#{@loader_name.id}")
    {declines: 1, declines_reasons: {standalone_instance_already_exists_for_default_ref: 1}}
  end

  def unknown_option
    log_to_table(
      "Error - unknown option for #{@loader_name.simple_name} #{@loader_name.id}"
    )
    log_error("Unknown option: ##{@match.id} #{@match.loader_name_id}")
    log_error("#{@match.inspect}")
    {errors: 1, errors_reasons: {unknown_option: 1}}
  end

  def standalone_instance_already_noted?
    true unless @match.standalone_instance_id.blank?
  end

  def no_default_ref?
    @loader_name.loader_batch.default_reference.blank?
  end

  def no_default_ref
    log_to_table("#{Constants::DECLINED_INSTANCE} - no batch default ref " +
                 "for #{@loader_name.simple_name} " + "#{@loader_name.id}")
    {declines: 1, declines_reasons: {no_batch_default_ref: 1}}
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
