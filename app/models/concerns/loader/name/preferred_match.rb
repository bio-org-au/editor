module Loader::Name::PreferredMatch
  extend ActiveSupport::Concern
  class NoPrimaryInstanceError < StandardError; end

  def can_clear_matches?
    loader_name_matches.collect { |m| m.standalone_instance_id }.compact.blank? &&
      loader_name_matches.collect { |m| m.relationship_instance_id }.compact.blank?
  end

  def create_match_to_loaded_from_instance_name(current_user)
    instance = Instance.find(loaded_from_instance_id)
    loader_name_match = ::Loader::Name::Match.new
    loader_name_match.loader_name_id = id
    loader_name_match.name_id = instance.name_id
    loader_name_match.instance_id = instance_id_for_match(instance)
    loader_name_match.relationship_instance_type_id = riti
    loader_name_match.created_by = loader_name_match.updated_by = current_user
    loader_name_match.save!
  rescue NoPrimaryInstanceError => e
    Rails.logger.error("#{e.to_s} - Instance: #{instance.id}; Name: #{instance.name.id}")
    Rails.logger.error("No primary instance isn't fatal, but no preferred match will be made.")
  end

  def instance_id_for_match(instance)
    if misapplied?
      instance.cites_id
    else
      instance_id_for_non_misapplied_match(instance)
    end
  end

  # Watch out for rare but possible case of no primary instance
  def instance_id_for_non_misapplied_match(instance)
    if instance.standalone?
      primary_instance = instance.name.primary_instances&.first
      if primary_instance.nil?
        raise NoPrimaryInstanceError.new
      end
      primary_instance.id
    else
      instance.id
    end
  end
end
