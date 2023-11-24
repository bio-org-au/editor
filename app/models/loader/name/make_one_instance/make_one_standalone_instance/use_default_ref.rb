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
class Loader::Name::MakeOneInstance::MakeOneStandaloneInstance::UseDefaultRef
  def initialize(loader_name, user, job)
    @tag = "#{self.class} for #{loader_name.simple_name} (#{loader_name.record_type})"
    @loader_name = loader_name
    @user = user
    @job = job
    @match = loader_name.preferred_match
    @task_start_time = Time.now
  end

  def create
    Rails.logger.debug("create")
    instance = Instance.new
    instance.draft = true
    instance.name_id = @match.name_id
    instance.reference_id = @loader_name.batch.default_reference_id
    instance.instance_type_id = InstanceType.secondary_reference.id
    instance.created_by = instance.updated_by = "bulk for #{@user}"
    instance.save!
    note_standalone_instance_created(instance)
    {creates: 1}
  rescue StandardError => e
    Rails.logger.error("#{self.class}#create: #{e}")
    Rails.logger.error e.backtrace.join("\n")
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    raise
  end

  def no_def_ref
    log_to_table("#{Constants::DECLINED_INSTANCE} - no default reference " +
                 "for #{@loader_name.simple_name} #{@loader_name.id}", @user, @job)
    {declines: 1, decline_reasons: {no_default_reference: 1} }
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

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
