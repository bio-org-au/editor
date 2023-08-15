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
  end

  def create
    debug("create")
    created = declined = errors = 0
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
    @match.source_for_copy.synonyms.each do |source_synonym|
      debug("copy syn #{source_synonym.id}")
      new_syn = Instance.new
      new_syn.cites_id = source_synonym.cites_id
      new_syn.cited_by_id = @new_standalone.id
      new_syn.instance_type_id = source_synonym.instance_type_id
      new_syn.created_by = new_syn.updated_by = "bulk for #{@user}"
      new_syn.name_id = source_synonym.name_id
      new_syn.reference_id = @new_standalone.reference_id
      new_syn.save!
      syns_copied += 1
      log("#{Constants::COPIED_SYN} #{new_syn.name.full_name}")
    end
    created += syns_copied
    [created, declined, errors]
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
    log("#{Constants::CREATED_INSTANCE} #{@new_standalone.name.full_name}")
  end

  def no_def_ref
    log("#{Constants::DECLINED_INSTANCE} - no default reference " +
                 "for #{@loader_name.simple_name} #{@loader_name.id}", @user, @job)
    Constants::DECLINED
  end

  def no_source_for_copy
    log("#{Constants::DECLINED_INSTANCE} - no source instance to " +
                 "copy #{@loader_name.simple_name} #{@loader_name.id}", @user, @job)
    Constants::DECLINED
  end

  def stand_already_noted
    log("#{Constants::DECLINED_INSTANCE} - standalone instance " +
                 "already noted for #{@loader_name.simple_name} " +
                 "#{@loader_name.id}")
    Constants::DECLINED
  end

  def stand_already_for_default_ref
    log("#{Constants::DECLINED_INSTANCE} - standalone instance " +
                 "exists for def ref for #{@loader_name.simple_name} " +
                 "#{@loader_name.id}")
    Constants::DECLINED
  end

  def using_existing_instance
    log("#{Constants::DECLINED_INSTANCE} - using existing " +
                 " instance for #{@loader_name.simple_name} #{@loader_name.id}")
    Constants::DECLINED
  end

  def unknown_option
    log(
      "Error - unknown option for #{@loader_name.simple_name} #{@loader_name.id}"
    )
    log_error("Unknown option: ##{@match.id} #{@match.loader_name_id}")
    log_error("#{@match.inspect}")
    Constants::ERROR
  end

  def standalone_instance_already_noted?
    return true unless @match.standalone_instance_id.blank?
  end

  def note_standalone_instance_created(instance)
    @match.standalone_instance_id = instance.id
    @match.standalone_instance_created = true
    @match.standalone_instance_found = false
    @match.updated_by = "job for #{@user}"
    @match.save!
    log("#{Constants::CREATED_INSTANCE} - standalone for " +
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

  def log(payload)
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  end
end
