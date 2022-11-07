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
class Loader::Name::AsInstanceCreator
  def initialize(loader_name, authorising_user, job_number)
    debug("initialize")
    debug("loader_name: #{loader_name}")
    debug("authorising_user: #{authorising_user}")
    debug("job_number: #{job_number}")
    #@tag = " job ##{job_number} for loader_name: #{loader_name.id}, seq: #{loader_name.seq} #{loader_name.scientific_name} (#{loader_name.true_record_type})"
    @loader_name = loader_name
    @authorising_user = authorising_user
    @job_number = job_number
  end

  # Adapted from Orchids logic
  # ###########################################################
  #
  #  if for accepted?
  #    - create standalone instance based on batch default reference
  #    OR
  #    - use the identified existing instance
  #    OR
  #    - create standalone instance based on batch default reference,
  #      append copies of synonyms from the identified existing instance
  #  elsif for synonym
  #    make sure the synonym's "accepted" name "parent" has an instance
  #    create or look for a relationship instance between the "parent"'s instance for
  #      the accepted name and the primary instance of the synonym
  #  elsif for hybrid?
  #    not sure yet
  #  elsif for misapp?
  #    not sure yet
  #  end
  #
  ###########################################################
  #
  # 
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
    return no_further_processing if @loader_name.excluded_from_further_processing?
    return no_preferred_match unless @loader_name.preferred_match?

    if @loader_name.accepted?
      return create_standalone
    elsif @loader_name.synonym?
      return create_synonymy
    elsif @loader_name.misapplied?
      return create_misapp
    else
      throw "Don't know how to handle loader_name #{@loader_name.id}"
    end
  end

  def no_further_processing
    log_to_table("declined - no further processing for #{@loader_name.id}")
    [0,1,0]
  end

  def no_preferred_match
    log_to_table("Declined - no preferred match for ##{@loader_name.id} #{@loader_name.simple_name}")
    [0,1,0]
  end

  def create_standalone
    return @loader_name.preferred_match.create_standalone_instance(@authorising_user, @job_number)
  end

  def create_synonymy
    return @loader_name.preferred_match
      .create_or_find_synonymy_instance(@authorising_user, @job_number)
  end

  def create_misapp
    Rails.logger.debug("create_misapp: matches: #{@loader_name.loader_name_matches.size}")
    created = declined = errors = 0
    @loader_name.loader_name_matches.each do |misapp_match|
      Rails.logger.debug("candidate match: #{misapp_match.inspect}")
      result = misapp_match.create_or_find_misapp_instance(@authorising_user, @job_number)
      created += result[0]
      declined += result[1]
      errors += result[2]
    end
    return [created, declined, errors]
  end

  def xcreate
    #return 0 if stop_everything?

    @created = 0
    @errors = 0
    @loader_name.preferred_match.each do |preferred_match|
      begin
        @created += preferred_match.create_instance(@ref, @authorising_user)
        log_create_action(@created)
      rescue => e
        @errors += 1
        log_to_table("Errors creating instance for preferred match #{preferred_match.id} - #{e.message}")
      end 
    end
  end

  def created
    @created
  end

  def errors
    @errors
  end

  def log_create_action(count)
    entry = "Create instance counted #{count} #{'record'.pluralize(count)}"
    log_to_table(entry)
  end

  def log_to_table(entry)
    BulkProcessingLog.log("Job ##{@job_number}: #{entry}", "Bulk job for #{@authorising_user}")
  rescue => e
    Rails.logger.error("Couldn't log to table: #{e.to_s}")
  end

  def scientific_name
    @loader_name.scientific_name
  end

  def record_failure(msg)
    msg.sub!(/uncaught throw /,'')
    msg.gsub!(/"/,'')
    msg.sub!(/^Failing/,'')
    Rails.logger.error("Loader::Name::AsInstanceCreator failure: #{msg}")
    log_to_table("Loader::Name::AsInstanceCreator failure: #{msg}")
  end

  def debug(msg)
    Rails.logger.debug("Loader::Name::AsInstanceCreator #{msg} #{@tag}")
  end
end
