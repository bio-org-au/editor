# A SuckerPunch job to refresh names.
class NameChildrenRefresherJob
  include SuckerPunch::Job

  def perform(name_id)
    names_refreshed = 0
    npaths_refreshed = 0
    Rails.logger.info("NameChildrenRefresherJob - a SuckerPunch::Job.")
    Rails.logger.info("May be asynchronous")
    ActiveRecord::Base.connection_pool.with_connection do
      name = Name.find(name_id)
      names_refreshed = name.refresh_tree
      npaths_refreshed = name.refresh_name_paths
    end
    names_refreshed
  end
end
