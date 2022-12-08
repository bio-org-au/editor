# frozen_string_literal: true

# Make a misapplication instance
class Loader::Name::MakeOneInstance::MakeOneMisappInstance
  def initialize(loader_name, match, user, job)
    @loader_name = loader_name
    @match = match
    @user = user
    @job = job
  end

  def create
    return already_noted if @match.relationship_instance_id.present?
    return misapp_already_attached if misapp_already_attached?
    return parent_using_existing if @loader_name.parent
                                                .preferred_match
                                                .use_existing_instance == true
    if @loader_name.parent.preferred_match.try("standalone_instance_id").blank?
      return parent_no_standalone
    end
    return no_relationship_instance_type if @match
                                            .relationship_instance_type_id
                                            .blank?

    create_misapp_instance
  rescue => e
    failed(e)
    raise
  end


  def failed(error)
    entry = "#{Constants::FAILED_INSTANCE} for #{@loader_name.simple_name} "
    entry += "#{@loader_name.id} - error in do_one_loader_name: #{error}"
    log_to_table(entry)
    Constants::ERROR
  end

  def no_relationship_instance_type
    log_to_table(declined_entry("No relationship instance type id "))
    Constants::DECLINED
  end

  def parent_no_standalone
    log_to_table(declined_entry(
      "parent has no standalone instance so cannot proceed")
    )
    Constants::DECLINED
  end

  def already_noted
    log_to_table(declined_entry(
        "relationship instance already noted (##{@match.relationship_instance_id})")
    )
    Constants::DECLINED
  end

  def misapp_already_attached
    record_misapp_already_there(@user)
    log_to_table(declined_entry("misapp already there"))
    Constants::DECLINED
  end

  def parent_using_existing
    log_to_table(declined_entry("parent is using existing instance"))
    Constants::DECLINED
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
    Constants::CREATED
  rescue => error
    Rails.logger.error("MakeOneMisappInstance#create_misapp_instance: #{e.to_s}")
    failed(error)
  end

  def note_misapp_created(instance)
    @match.relationship_instance_created = true
    @match.relationship_instance_id = instance.id
    @match.updated_by = "bulk for #{@user}"
    @match.save!
    log_to_table("#{Constants::CREATED_INSTANCE} for loader_name ##{@loader_name.id} #{@loader_name.simple_name}")
  end

  def log_to_table(entry)
    BulkProcessingLog.log("Job ##{@job}: #{entry}", @user)
  rescue => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end
end
