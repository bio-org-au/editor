module Name::CopyInstances
  extend ActiveSupport::Concern

  def copy_instances
    raise "Please supply a target Name" if name_params[:target_name_id].blank?
    raise "Please choose one or more instances" if name_params[:instance_ids_to_copy].compact_blank.blank?

    @target_name = Name.find(name_params[:target_name_id])
    @tally = @name.copy_standalone_instances(@target_name, name_params[:instance_ids_to_copy].compact_blank, current_user.username)
    render "names/copy_instances/success"
  rescue StandardError => e
    @message = e.to_s
    logger.error("Error in Name#copy_instances: #{@message}")
    render "names/copy_instances/error"
  end
end
