
#
# Names can be in a loader batch
module NameLoadable
  extend ActiveSupport::Concern

  def matched_to_loader_name?
    ::Loader::Name::Match.where(name_id: self.id).size > 0
  end
end
