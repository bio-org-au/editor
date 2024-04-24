
#
# Names can be in a loader batch
module Name::Loadable
  extend ActiveSupport::Concern

  def matched_to_loader_name?
    matches.size > 0
  rescue StandardError => e
    Rails.logger.error("Error checking matched_to_loader_name: #{e.to_s}")
    false
  end

  def matches
    ::Loader::Name::Match.where(name_id: self.id)
  rescue StandardError => e
    Rails.logger.error("Error checking matches: #{e.to_s}")
    []
  end

end
