module Loader::Name::SourcedSynonyms
  extend ActiveSupport::Concern
    def create_sourced_synonyms_for_instance(instance_id, current_user)
      logger.debug("instance id: #{instance_id}")
      instance = Instance.find(instance_id)
      sourced_syns = instance.synonyms_for_copy_to_loader_name

      seq_value = loader_batch.use_sort_key_for_ordering ? 0 : seq
      sourced_syns.each do |sou_syn| 
        seq_value += 1 unless loader_batch.use_sort_key_for_ordering
        s = ::Loader::Name.new(loader_batch_id: loader_batch_id,
                               record_type: syn_or_misapp(sou_syn),
                               parent_id: self.id,
                               synonym_type: sou_syn.instance_type.name,
                               simple_name: sou_syn.name.simple_name,
                               simple_name_as_loaded: sou_syn.name.simple_name,
                               full_name: sou_syn.name.full_name,
                               family: sou_syn.name.family.simple_name,
                               doubtful: sou_syn.instance_type.doubtful,
                               loaded_from_instance_id: sou_syn.cites_id,
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

