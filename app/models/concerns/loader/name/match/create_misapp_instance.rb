
module Loader::Name::Match::CreateMisappInstance
  extend ActiveSupport::Concern
  def create_or_find_misapp_instance(user, job)
    Rails.logger.debug("create_or_find_relationship_instance for id: #{loader_name.simple_name} ##{loader_name.id}")
    if relationship_instance_id.present?
      entry = "Declined: relationship instance already "
      entry += "noted (##{relationship_instance_id}) for "
      entry += "#{loader_name.simple_name} ##{loader_name.id}"
      log_to_table(entry, user, job)
      return Loader::Name::Match::DECLINED
    end
    if misapp_already_attached?
      record_misapp_already_there(user)
      entry = "Declined: misapp already there for "
      entry += "#{loader_name.simple_name} ##{loader_name.id}"
      log_to_table(entry, user, job)
      return Loader::Name::Match::DECLINED
    end
    if loader_name.parent.preferred_match.use_existing_instance == true
      entry = "Declined: parent is using existing instance for "
      entry += "#{loader_name.simple_name} ##{loader_name.id}"
      log_to_table(entry, user, job)
      return Loader::Name::Match::DECLINED
    end
    #return create_relationship_instance(user, job)
    return create_misapp_instance(user, job)
  rescue => e
    entry = "Failed to create instance for #{loader_name.simple_name} "
    entry += "##{loader_name.id} - error in do_one_loader_name: #{e.to_s}"
    log_to_table(entry, user, job)
    #return Loader::Name::Match::ERROR
    raise
  end

  def misapp_already_attached?
    return false if loader_name.parent.loader_name_matches.blank?
    return false if loader_name.parent.loader_name_matches.first.try('standalone_instance_id').blank?

    instances = Instance.where(name_id: name_id)
                        .where(cites_id: instance_id)
                        .where(cited_by_id: loader_name.parent.loader_name_matches.first.try('standalone_instance_id'))
    return !instances.blank?
  end
      
  def record_misapp_already_there(user)
    instances = Instance.where(name_id: name_id)
                        .where(cites_id: instance_id)
                        .where(cited_by_id: loader_name.parent.loader_name_matches.first.try('standalone_instance_id'))
    self.relationship_instance_found = true
    self.relationship_instance_id = instances.first.id
    self.created_by = self.updated_by = "bulk for #{user}"
    self.save!
    return true
  end

  def create_misapp_instance(user, job)
    if loader_name.parent.loader_name_matches.first.try('standalone_instance_id').blank?
      entry = "Declined: loader name parent has no standalone instance so cannot proceed "
      entry += "#{loader_name.simple_name} ##{loader_name.id}"
      log_to_table(entry, user, job)
      return [0,1,0]
    else  
      new_instance = Instance.new
      new_instance.draft = false
      new_instance.cited_by_id = loader_name.parent.loader_name_matches.first.standalone_instance_id
      new_instance.reference_id = loader_name.parent.loader_name_matches.first.standalone_instance.reference_id
      new_instance.cites_id = instance_id
      new_instance.name_id = instance.name_id
      throw "No relationship instance type id for #{id} #{loader_name.simple_name}" if relationship_instance_type_id.blank?
      new_instance.instance_type_id = relationship_instance_type_id
      new_instance.created_by = new_instance.updated_by = "bulk for #{user}"
      new_instance.save!
      note_misapp_created(new_instance, user, job)
      return [1,0,0]
    end
  rescue => e
    entry = "LoaderNameMatch#create_one_misapp_instance: #{e.to_s}"
    logger.error(entry)
    log_to_table(entry, user, job)
    return [0,0,1]
  end

  def note_misapp_created(instance, user, job)
    self.relationship_instance_created = true
    self.relationship_instance_id = instance.id
    self.updated_by = "bulk for #{user}"
    self.save!
    log_to_table("Created misapplication instance for loader_name " +
                 "##{loader_name.id} #{loader_name.simple_name}",
                 user, job)
  end
end
