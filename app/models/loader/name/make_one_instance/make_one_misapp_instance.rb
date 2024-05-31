# frozen_string_literal: true

# Make a misapplication instance
class Loader::Name::MakeOneInstance::MakeOneMisappInstance
  def initialize(loader_name, match, user, job)
    @loader_name = loader_name
    @match = match
    @user = user
    @job = job
    @task_start_time = Time.now
  end

  def create
    return already_noted if @match.relationship_instance_id.present?
    return misapp_already_attached if misapp_already_attached?
    return parent_no_preferred_match if @loader_name.parent
                     .preferred_match.blank?
    return parent_using_existing if @loader_name.parent
                                                .preferred_match
                                                .use_existing_instance == true
    return parent_no_standalone if @loader_name.parent.preferred_match.try("standalone_instance_id").blank?
    return no_relationship_instance_type if @match
                                            .relationship_instance_type_id
                                            .blank?

    create_misapp_instance
  rescue StandardError => e
    failed(e)
    raise
  end

  def failed(error)
    entry = "#{Constants::FAILED_INSTANCE} for #{@loader_name.simple_name} "
    entry += "#{@loader_name.id} - error in make_one_misapp_instance: #{error}"
    log_to_table(entry)
    {errors: 1, errors_reasons: {"#{error}": 1}}
  end

  def no_relationship_instance_type
    log_to_table(declined_entry("No relationship instance type id "))
    {declines: 1, declines_reasons: {no_relationship_instance_type_id: 1}}
  end

  def parent_no_standalone
    log_to_table(declined_entry(
                   "parent has no standalone instance so cannot proceed"
                 ))
    {declines: 1, declines_reasons: {parent_has_no_standalone_instance: 1}}
  end

  def already_noted
    log_to_table(declined_entry(
                   "relationship instance already noted (##{@match.relationship_instance_id})"
                 ))
    {declines: 1, declines_reasons: {relationship_instance_already_noted: 1}}
  end

  def misapp_already_attached
    record_misapp_already_there
    log_to_table(declined_entry("misapplied instance already there"))
    {declines: 1, declines_reasons: {misapplied_instance_already_there: 1}}
  end

  def parent_using_existing
    log_to_table(declined_entry("parent is using existing instance"))
    {declines: 1, declines_reasons: {parent_is_using_existing_instance: 1}}
  end

  def parent_no_preferred_match
    log_to_table(declined_entry("parent has no preferred match"))
    {declines: 1, declines_reasons: {parent_has_no_preferred_match: 1}}
  end

  def declined_entry(message)
    "#{Constants::DECLINED_INSTANCE}: #{message} for #{@loader_name.simple_name} ##{@loader_name.id}"
  end

  def misapp_already_attached?
    return false if @loader_name.parent.loader_name_matches.blank?
    return false if @loader_name.parent.loader_name_matches.first.try("standalone_instance_id").blank?

    instances = Instance.where(name_id: @match.name_id)
                        .where(cites_id: @match.instance_id)
                        .where(cited_by_id: @loader_name.parent.loader_name_matches.first.try("standalone_instance_id"))
    !instances.blank?
  end

  def record_misapp_already_there
    instances = Instance.where(name_id: @match.name_id)
                        .where(cites_id: @match.instance_id)
                        .where(cited_by_id: @loader_name.parent.loader_name_matches.first.try("standalone_instance_id"))
    @match.relationship_instance_found = true
    @match.relationship_instance_id = instances.first.id
    @match.created_by = @match.updated_by = "bulk for #{@user}"
    @match.save!
    true
  end

  def create_misapp_instance
    new_instance = Instance.new
    new_instance.draft = false
    new_instance.cited_by_id = @loader_name.parent.loader_name_matches.first.standalone_instance_id
    new_instance.reference_id = @loader_name.parent.loader_name_matches.first.standalone_instance.reference_id
    new_instance.cites_id = @match.instance_id
    new_instance.name_id = @match.instance.name_id
    new_instance.instance_type_id = @match.relationship_instance_type_id
    new_instance.created_by = new_instance.updated_by = "bulk for #{@user}"
    new_instance.save!
    note_misapp_created(new_instance)
    {creates: 1}
  rescue StandardError => e
    Rails.logger.error("MakeOneMisappInstance#create_misapp_instance: #{e}")
    failed(e)
    {errors: 1, errors_reasons: {"#{e.to_s}": 1}}
  end

  def note_misapp_created(instance)
    @match.relationship_instance_created = true
    @match.relationship_instance_id = instance.id
    @match.updated_by = "bulk for #{@user}"
    @match.save!
    log_to_table("#{Constants::CREATED_INSTANCE} for loader_name ##{@loader_name.id} #{@loader_name.simple_name}")
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
