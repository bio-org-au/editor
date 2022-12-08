
class Loader::Batch::BulkController::JobLockedError < StandardError
  def initialize(tag="unknown", exception_type="custom")
    @exception_type = exception_type
    super("Cannot run #{tag} because loader batch jobs are locked - another job is probably running.")
  end
end

