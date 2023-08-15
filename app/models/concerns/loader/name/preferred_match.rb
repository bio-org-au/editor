module Loader::Name::PreferredMatch
  extend ActiveSupport::Concern

  def can_clear_matches?
    loader_name_matches.collect { |m| m.standalone_instance_id }.compact.blank? &&
      loader_name_matches.collect { |m| m.relationship_instance_id }.compact.blank?
  end
end
