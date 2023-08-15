# A SuckerPunch job to refresh names.
class CreateOrchidInstancesJob
  include SuckerPunch::Job

  # what about locking?
  # trial code, not yet running
  def perform(_taxon_string, _username)
    records = Orchid.create_instance_for_preferred_matches_for(params[:taxon_string], @current_user.username)
    @message = "Created #{records} draft #{'instance'.pluralize(records)} for #{params[:taxon_string]}"
    OrchidBatchJobLock.unlock!
  rescue StandardError => e
    logger.error("OrchidsBatchController#create_instances_for_preferred_matches: #{e}")
    logger.error e.backtrace.join("\n")
  end
end
