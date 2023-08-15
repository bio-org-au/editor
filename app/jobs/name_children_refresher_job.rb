# A SuckerPunch job to refresh names.
class NameChildrenRefresherJob
  include SuckerPunch::Job

  def perform(name_id)
    total = 0
    npaths = 0
    Rails.logger.info("NameChildrenRefresherJob - a SuckerPunch::Job.")
    Rails.logger.info("May be asynchronous")
    ActiveRecord::Base.connection_pool.with_connection do
      name = Name.find(name_id)
      total = name.refresh_tree
      npaths = name.refresh_name_paths
    end
    total
  end
end
