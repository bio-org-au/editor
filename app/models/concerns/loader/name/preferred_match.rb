module Loader::Name::PreferredMatch
  extend ActiveSupport::Concern

  def can_clear_matches?
    loader_name_matches.collect { |m| m.standalone_instance_id }.compact.blank? &&
      loader_name_matches.collect { |m| m.relationship_instance_id }.compact.blank?
  end

  def create_match_to_loaded_from_instance_name(current_user)
    instance = Instance.find(loaded_from_instance_id)
    loader_name_match = ::Loader::Name::Match.new
    loader_name_match.loader_name_id = id
    loader_name_match.name_id = instance.name_id
    loader_name_match.instance_id = instance.id
    loader_name_match.relationship_instance_type_id = riti
    loader_name_match.created_by = loader_name_match.updated_by = current_user
    loader_name_match.save!
  end
end
