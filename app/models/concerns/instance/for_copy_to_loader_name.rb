# frozen_string_literal: true

module Instance::ForCopyToLoaderName
  extend ActiveSupport::Concern

  class_methods do
    def sourced_sibling_synonyms_and_misapps(instance)
      Instance.where(cited_by_id: instance.this_is_cited_by)
              .where.not(id: instance.id) 
              .joins(:instance_type)
              .where(instance_type: { unsourced: false })
              .where.not(instance_type: { name: 'trade name' })
    end
  end

  def loader_name_for_accepted_excluded
    loader_name = Loader::Name.new
    loader_name.simple_name = name.simple_name
    loader_name.full_name = name.full_name
    loader_name.family = name.family.simple_name
    loader_name.rank = name.name_rank.display_name.downcase
    loader_name.name_status = name.name_status.name.downcase.sub(/\Alegitimate\z/,'')
    loader_name.record_type = name.excluded_concept? ? 'excluded' : 'accepted'
    loader_name.loaded_from_instance_id = self.id
    loader_name.distribution = accepted_tree_version_element&.distribution
    loader_name.comment = accepted_tree_version_element&.comment
    loader_name
  end

  def loader_name_for_synonym_flip_to_accepted
    loader_name = Loader::Name.new
    loader_name.simple_name = name.simple_name
    loader_name.full_name = name.full_name
    loader_name.family = name.family.simple_name
    loader_name.rank = name.name_rank.display_name.downcase
    loader_name.record_type = 'accepted'
    loader_name.loaded_from_instance_id = self.id
    loader_name.name_status = name.name_status.name.downcase.sub(/\Alegitimate\z/,'')
    loader_name.comment = name.accepted_or_excluded_comment
    loader_name.distribution = name.accepted_distribution
    loader_name.add_sibling_synonyms = true
    loader_name
  end

  def synonyms_for_copy_to_loader_name
    copyable_syns = synonyms.reject {|s| s.instance_type.unsourced}
                            .reject {|s| s.instance_type.name == 'trade name'}
    copyable_syns
  end
end
