class Loader::Name::MakeOneInstance::MakeOneSynonymyInstance
  def initialize(loader_name, user, job)
    @tag = "#{self.class} for #{loader_name.simple_name} (#{loader_name.record_type})"
    @loader_name = loader_name
    @user = user
    @job = job
    @match = loader_name.preferred_match
    @task_start_time = Time.now
  end

  def create
    Rails.logger.debug("create_or_find_relationship_instance for id: #{@loader_name.simple_name} ##{@loader_name.id}")
    if @match.relationship_instance_id.present?
      entry = "#{Constants::DECLINED_INSTANCE} -: relationship instance already "
      entry += "noted (##{@match.relationship_instance_id}) for "
      entry += "#{@loader_name.simple_name} ##{@loader_name.id}"
      log_to_table(entry)
      return {declines: 1, decline_reasons: {relationship_instance_already_noted: 1}}
    end
    if @loader_name.parent.preferred_match.blank?
      entry = "#{Constants::DECLINED_INSTANCE} -: parent has no preferred match"
      entry += " #{@loader_name.simple_name} ##{@loader_name.id}"
      log_to_table(entry)
      return {declines: 1, decline_reasons: {parent_has_no_preferred_match: 1}}
    end
    if @loader_name.parent.preferred_match.use_existing_instance == true
      entry = "#{Constants::DECLINED_INSTANCE} -: parent is using existing instance for "
      entry += "#{@loader_name.simple_name} ##{@loader_name.id}"
      log_to_table(entry)
      return {declines: 1, decline_reasons: {parent_is_using_existing_instance: 1}}
    end
    if synonym_already_attached?
      record_synonym_already_there
      entry = "#{Constants::DECLINED_INSTANCE} -: synonym already in place for "
      entry += "#{@loader_name.simple_name} ##{@loader_name.id}"
      log_to_table(entry)
      return {declines: 1, decline_reasons: {synonym_already_in_place: 1}}
    end
    create_relationship_instance
  rescue StandardError => e
    entry = "#{Constants::ERROR_INSTANCE} - for #{@loader_name.simple_name} "
    entry += "##{@loader_name.id} - error in create: #{e}"
    log_to_table(entry)
    {errors: 1, error_reasons: {"#{e.to_s}": 1}}
  end

  def synonym_already_attached?
    return false if @loader_name.parent.loader_name_matches.blank?
    return false if @loader_name.parent.loader_name_matches.first.try("standalone_instance_id").blank?

    instances = Instance.where(name_id: @match.name_id)
                        .where(cites_id: @match.instance_id)
                        .where(cited_by_id: @loader_name.parent.loader_name_matches.first.try("standalone_instance_id"))
    !instances.blank?
  end

  def record_synonym_already_there
    instances = Instance.where(name_id: @match.name_id)
                        .where(cites_id: @match.instance_id)
                        .where(cited_by_id: @loader_name.parent.loader_name_matches.first.try("standalone_instance_id"))
    @match.relationship_instance_found = true
    @match.relationship_instance_id = instances.first.id
    @match.created_by = @match.updated_by = "bulk for #{@user}"
    @match.save!
    true
  end

  def create_relationship_instance
    if @loader_name.parent.loader_name_matches.first.try("standalone_instance_id").blank?
      entry = "#{Constants::DECLINED_INSTANCE} - loader name parent" +
              " has no standalone instance so cannot proceed " +
              "#{@loader_name.simple_name} ##{@loader_name.id}"
      log_to_table(entry)
      return {declines: 1, decline_reasons: {parent_has_no_standalone_instance: 1}}
    end
    new_instance = Instance.new
    new_instance.draft = false
    new_instance.cited_by_id = @loader_name.parent.loader_name_matches.first.standalone_instance_id
    new_instance.reference_id = @loader_name.parent.loader_name_matches.first.standalone_instance.reference_id
    new_instance.cites_id = @match.instance_id
    new_instance.name_id = @match.instance.name_id
    if @match.relationship_instance_type_id.blank?
      throw "No relationship instance type id for #{id} #{@loader_name.simple_name}"
    end
    new_instance.instance_type_id = @match.relationship_instance_type_id
    new_instance.created_by = new_instance.updated_by = "#{@user}"
    new_instance.save!
    note_created(new_instance)
    {creates: 1}
  rescue StandardError => e
    entry = "LoaderNameMatch#create_relationship_instance: ##{@loader_name.id} #{e}"
    Rails.logger.error(entry)
    entry = "#{Constants::FAILED_INSTANCE}: #{@loader_name.simple_name} ##{@loader_name.id} #{e}"
    log_to_table(entry)
    {errors: 1, error_reasons: {"#{e.to_s}": 1}}
  end

  def note_created(instance)
    @match.relationship_instance_created = true
    @match.relationship_instance_id = instance.id
    @match.updated_by = "#job for #{@user}"
    @match.save!
    log_to_table("#{Constants::CREATED_INSTANCE} - for " +
                 "##{@loader_name.id} #{@loader_name.simple_name}")
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
