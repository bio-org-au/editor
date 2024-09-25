module Loader::Name::FlippedSynonym
  extend ActiveSupport::Concern
    def create_flipped_synonym_for_instance(instance_id, current_user)
      logger.debug("instance id: #{instance_id}")
      instance = Instance.find(instance_id)
      seq_value = loader_batch.use_sort_key_for_ordering ? 0 : seq
      seq_value += 1 unless loader_batch.use_sort_key_for_ordering
      synonym = ::Loader::Name.new(loader_batch_id: loader_batch_id,
                               record_type: 'synonym',
                               parent_id: self.id,
                               synonym_type: instance.instance_type.name,
                               simple_name: instance.name.simple_name,
                               simple_name_as_loaded: instance.name.simple_name,
                               full_name: instance.name.full_name,
                               family: instance.name.family.simple_name,
                               rank: instance.name.name_rank.name.downcase,
                               name_status: instance.name.name_status.name.downcase,
                               doubtful: false,
                               loaded_from_instance_id: instance.id,
                               created_manually: true,
                               created_by: current_user.username,
                               updated_by: current_user.username,
                               seq: seq_value
                              )
      synonym.consider_sort_key
      synonym.name_status = nil if ['legitimate','[n/a]'].include?(synonym.name_status)
      synonym.save!
      synonym.create_match_to_loaded_from_instance_name(current_user.username)
    end
end

