module Loader::Name::SiblingSynonyms
  extend ActiveSupport::Concern
    def create_sibling_synonyms_for_instance(instance_id, current_user)
      logger.debug("instance id: #{instance_id}")
      syn = Instance.find(instance_id)
      siblings = Instance.sourced_sibling_synonyms_and_misapps(syn)
      seq_value = loader_batch.use_sort_key_for_ordering ? 0 : seq
      logger.debug("batch id: #{loader_batch_id}")
      siblings.each do |instance| 
        logger.debug("==============================")
        seq_value += 1 unless loader_batch.use_sort_key_for_ordering
        s = ::Loader::Name.new(loader_batch_id: loader_batch_id,
                               record_type: syn_or_misapp(instance),
                               parent_id: self.id,
                               synonym_type: instance.instance_type.name,
                               simple_name: instance.name.simple_name,
                               simple_name_as_loaded: instance.name.simple_name,
                               full_name: instance.name.full_name,
                               family: instance.name.family.simple_name,
                               rank: instance.name.name_rank.display_name
                                       .downcase,
                               doubtful: instance.instance_type.doubtful,
                               loaded_from_instance_id: instance.id,
                               created_manually: true,
                               created_by: current_user.username,
                               updated_by: current_user.username,
                               seq: seq_value
                              )
        s.consider_sort_key
        s.attribute_names.each do |a| 
          logger.debug("#{a} : #{s[a]}") unless s[a].blank?
        end
        s.save!
        s.create_match_to_loaded_from_instance_name(current_user.username)
      end
    end

    def syn_or_misapp(instance)
      return 'synonym' if instance.instance_type.synonym

      return 'misapplied' if instance.instance_type.misapplied

      return 'unknown'
    end
end

