# frozen_string_literal: true


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

# Name fields that are offered for the various types and categories of names.
module Loader::Name::Match::CreateStandaloneInstance
  extend ActiveSupport::Concern
  def create_standalone_instance(user, job)
    case
    when instance_choice_confirmed == false
      self.use_batch_default_reference = true
      self.instance_choice_confirmed = true
      return create_using_default_ref(user, job)
    when use_batch_default_reference == true
      return create_using_default_ref(user, job)
    when copy_append_from_existing_use_batch_def_ref == true
      return copy_and_append(user, job)
    when use_existing_instance == true 
      return using_existing_instance(user, job)
    else
      return unknown_option(user, job)
    end
  end

  def log_error(msg)
    Rails.logger.error(msg)
  end

  def no_instance_choice_confirmed(user, job)
    log_to_table("Declined - no instance choice confirmed for " +
                 "#{loader_name.simple_name} #{loader_name.id}",
                 user, job)
    return Loader::Name::Match::DECLINED
  end

  def create_using_default_ref(user, job)
    return no_def_ref(user, job) if loader_name.loader_batch.default_reference.blank?
    return stand_already_noted(user, job) if standalone_instance_already_noted?
    return stand_already_for_default_ref(user, job) if standalone_instance_for_default_ref?

    return really_create_standalone_instance(
      loader_name.loader_batch.default_reference,
      user,
      job)
  end

  def no_def_ref(user, job)
    log_to_table("Declined - no default reference for #{loader_name.simple_name} #{loader_name.id}",
                 user, job)
    return Loader::Name::Match::DECLINED
  end

  def no_source_for_copy(user, job)
    log_to_table("Declined - no source instance to copy #{loader_name.simple_name} #{loader_name.id}",
                 user, job)
    return Loader::Name::Match::DECLINED
  end

  def stand_already_noted(user, job)
    log_to_table("Declined - standalone instance already noted for #{loader_name.simple_name} #{loader_name.id}",
                 user, job)
    return [0,1,0]
  end

  def stand_already_for_default_ref(user, job)
    log_to_table(
      "Declined - standalone instance exists for def ref for #{loader_name.simple_name} #{loader_name.id}",
      user, job)
    return Loader::Name::Match::DECLINED
  end

  def copy_and_append(user, job)
    return no_def_ref(user, job) if loader_name.loader_batch.default_reference.blank?
    return stand_already_noted(user, job) if standalone_instance_already_noted?
    return stand_already_for_default_ref(user, job) if standalone_instance_for_default_ref?
    return no_source_for_copy(user, job) if source_for_copy.blank?

    # STANDALONE INSTANCE
    # create a standalone instance really_create_standalone_instance
    new_standalone = Instance.new
    new_standalone.draft = true
    new_standalone.name_id = name_id
    new_standalone.reference_id = loader_name.loader_batch.default_reference.id
    new_standalone.instance_type_id = InstanceType.secondary_reference.id
    new_standalone.created_by = new_standalone.updated_by = "bulk for #{user}"
    new_standalone.save!

    # # NOTE INSTANCE CREATED
    self.standalone_instance_id = new_standalone.id
    self.standalone_instance_created = true
    self.standalone_instance_found = false
    self.updated_by = "job for #{user}"
    self.save!
    
    Rails.logger.debug("#{' '*138}=")
    Rails.logger.debug("#{' '*138}=")
    Rails.logger.debug("#{' '*138}=")
    Rails.logger.debug("copy_and_append")
    Rails.logger.debug("===============")
    Rails.logger.debug("copy_and_append: id: #{self.id}")
    Rails.logger.debug("copy_and_append: need to create a standalone instance based on batch def ref")
    Rails.logger.debug("copy_and_append: need to find the source instance")
    Rails.logger.debug("copy_and_append: source_for_copy.id: #{source_for_copy.id}")
    Rails.logger.debug("copy_and_append: source_for_copy.class: #{source_for_copy.class}")
    Rails.logger.debug("copy_and_append: source_for_copy.synonyms.size: #{source_for_copy.synonyms.size}")
    Rails.logger.debug("copy_and_append: source_for_copy.synonyms.collect ids: #{source_for_copy.synonyms.collect {|cit| cit.id}.inspect}")
    syns_created = 0
    source_for_copy.synonyms.each do |source_synonym|
      Rails.logger.debug("create synonym from source #{source_synonym.id} for new standalone instance #{new_standalone.id}")
      new_syn = Instance.new
      new_syn.cites_id = source_synonym.cites_id
      new_syn.cited_by_id = new_standalone.id
      new_syn.instance_type_id = source_synonym.instance_type_id
      new_syn.created_by = new_syn.updated_by = "bulk for #{user}"
      new_syn.name_id = source_synonym.name_id
      new_syn.reference_id = new_standalone.reference_id
      new_syn.save!
      syns_created += 1
      log_to_table(
        "Copy-and-append synonym created for #{new_syn.name.full_name}",
        user, job)
    end
    Rails.logger.debug("#{' '*138}=")
    Rails.logger.debug("#{' '*138}=")
    Rails.logger.debug("#{' '*138}=")

    log_to_table(
      "Created standalone with #{syns_created} synonym (copy-and-append) for #{loader_name.simple_name} #{loader_name.id}",
      user, job)
    return Loader::Name::Match::CREATED
  end

  def using_existing_instance(user, job)
    log_to_table(
      "Declined - using existing instance for #{loader_name.simple_name} #{loader_name.id}",
      user, job)
    return Loader::Name::Match::DECLINED
  end

  def unknown_option(user, job)
    log_to_table(
      "Error - unknown option for #{loader_name.simple_name} #{loader_name.id}",
      user, job)
    log_error("Unknown option: ##{self.id} #{self.loader_name_id}")
    log_error("#{self.inspect}")
    return Loader::Name::Match::ERROR
  end

  def standalone_instance_already_noted?
    return true unless standalone_instance_id.blank?
  end

  def standalone_instance_for_default_ref?
    instances =  find_standalone_instances_for_default_ref
    case instances.size
    when 0
      false
    when 1
      note_standalone_instance(instances.first)
      true
    else
      throw 'Unexpected 2+ standalone instances'
    end
  end

  def find_standalone_instances_for_default_ref
    Instance.where(name_id: name_id)
             .where(reference_id:
                    loader_name.loader_batch.default_reference.id)
             .joins(:instance_type)
             .where(instance_type: { standalone: true})
  end

  def note_standalone_instance_created(instance, user, job)
    self.standalone_instance_id = instance.id
    self.standalone_instance_created = true
    self.standalone_instance_found = false
    self.updated_by = "job for #{user}"
    self.save!
    log_to_table("Created standalone instance for loader_name " +
                 "##{self.loader_name_id} #{loader_name.simple_name}",
                 user, job)
  end

  def note_standalone_instance(instance)
    Rails.logger.debug('note_standalone_instance')
    self.standalone_instance_id = instance.id
    self.standalone_instance_found = true
    self.updated_by = 'job'
    self.save!
  end
 
  def really_create_standalone_instance(ref, user, job)
    Rails.logger.debug('really_create_standalone_instance')
    instance = Instance.new
    instance.draft = true
    instance.name_id = name_id
    instance.reference_id = ref.id 
    instance.instance_type_id = InstanceType.secondary_reference.id
    instance.created_by = instance.updated_by = "bulk for #{user}"
    instance.save!
    note_standalone_instance_created(instance, user, job)
    return Loader::Name::Match::CREATED
  rescue => e
    logger.error("Loader::Name::Match#really_create_standalone_instance: #{e.to_s}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s.sub(/uncaught throw/,'').gsub(/"/,'')
    raise
  end

  def log_to_table(entry, user, job)
    BulkProcessingLog.log("Job ##{job}: #{entry}","Bulk job for #{user}")
  rescue => e
    Rails.logger.error("Couldn't log to table: #{e.to_s}")
  end
end
