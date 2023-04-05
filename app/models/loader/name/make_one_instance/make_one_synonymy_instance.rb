
class Loader::Name::MakeOneInstance::MakeOneSynonymyInstance
  def initialize(loader_name, user, job)
    @tag = "#{self.class} for #{loader_name.simple_name} (#{loader_name.record_type})"
    @loader_name = loader_name
    @user = user
    @job = job
    @match = loader_name.preferred_match
  end

  def create
    Rails.logger.debug("create_or_find_relationship_instance for id: #{@loader_name.simple_name} ##{@loader_name.id}")
    if @match.relationship_instance_id.present?
      entry = "#{Constants::DECLINED_INSTANCE} -: relationship instance already "
      entry += "noted (##{@match.relationship_instance_id}) for "
      entry += "#{@loader_name.simple_name} ##{@loader_name.id}"
      log(entry)
      return Constants::DECLINED
    end
    if @loader_name.parent.preferred_match.blank?
      entry = "#{Constants::DECLINED_INSTANCE} -: parent has no preferred match"
      entry += " #{@loader_name.simple_name} ##{@loader_name.id}"
      log(entry)
      return Constants::DECLINED
    end
    if @loader_name.parent.preferred_match.use_existing_instance == true
      entry = "#{Constants::DECLINED_INSTANCE} -: parent is using existing instance for "
      entry += "#{@loader_name.simple_name} ##{@loader_name.id}"
      log(entry)
      return Constants::DECLINED
    end
    if synonym_already_attached?
      record_synonym_already_there
      entry = "#{Constants::DECLINED_INSTANCE} -: synonym already there for "
      entry += "#{@loader_name.simple_name} ##{@loader_name.id}"
      log(entry)
      return Constants::DECLINED
    end
    return create_relationship_instance
  rescue => e
    entry = "#{Constants::ERROR_INSTANCE} - for #{@loader_name.simple_name} "
    entry += "##{@loader_name.id} - error in do_one_loader_name: #{e.to_s}"
    log(entry)
    return Constants::ERROR
  end

  def synonym_already_attached?
    return false if @loader_name.parent.loader_name_matches.blank?
    return false if @loader_name.parent.loader_name_matches.first.try('standalone_instance_id').blank?

    instances = Instance.where(name_id: @match.name_id)
                        .where(cites_id: @match.instance_id)
                        .where(cited_by_id: @loader_name.parent.loader_name_matches.first.try('standalone_instance_id'))
    return !instances.blank?
  end
      
  def record_synonym_already_there
    instances = Instance.where(name_id: @match.name_id)
                        .where(cites_id: @match.instance_id)
                        .where(cited_by_id: @loader_name.parent.loader_name_matches.first.try('standalone_instance_id'))
    @match.relationship_instance_found = true
    @match.relationship_instance_id = instances.first.id
    @match.created_by = @match.updated_by = "bulk for #{@user}"
    @match.save!
    return true
  end

  def create_relationship_instance
    Rails.logger.debug('create_relationship_instance start')
    if @loader_name.parent.loader_name_matches.first.try('standalone_instance_id').blank?
      Rails.logger.debug('loader name parent has no standalone instance so cannot create relationship instance')
      entry = "#{Constants::DECLINED_INSTANCE} - loader name parent" +
      " has no standalone instance so cannot proceed " +
      "#{@loader_name.simple_name} ##{@loader_name.id}"
      log(entry)
      return Constants::DECLINED
    else
      Rails.logger.debug('qfter three')
    end
    Rails.logger.debug('Going on to create relationship instance')
    new_instance = Instance.new
    new_instance.draft = false
    new_instance.cited_by_id = @loader_name.parent.loader_name_matches.first.standalone_instance_id
    new_instance.reference_id = @loader_name.parent.loader_name_matches.first.standalone_instance.reference_id
    new_instance.cites_id = @match.instance_id
    new_instance.name_id = @match.instance.name_id
    throw "No relationship instance type id for #{id} #{@loader_name.simple_name}" if @match.relationship_instance_type_id.blank?
    new_instance.instance_type_id = @match.relationship_instance_type_id
    new_instance.created_by = new_instance.updated_by = "#{@user}"
    new_instance.save!
    note_created(new_instance)
    return Constants::CREATED
  rescue => e
    entry = "LoaderNameMatch#create_relationship_instance: #{e.to_s}"
    Rails.logger.error(entry)
    entry = "#{Constants::FAILED_INSTANCE}: #{e.to_s}"
    log(entry)
    return Constants::ERROR
  end

  def note_created(instance)
    @match.relationship_instance_created = true
    @match.relationship_instance_id = instance.id
    @match.updated_by = "#job for #{@user}"
    @match.save!
    log("#{Constants::CREATED_INSTANCE} - for " +
                 "##{@loader_name.id} #{@loader_name.simple_name}")
  end

  def log(payload)
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  end

end
