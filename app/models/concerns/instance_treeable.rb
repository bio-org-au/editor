# frozen_string_literal: true

# Names can be in a classification tree
module InstanceTreeable
  extend ActiveSupport::Concern

  def accepted_tree_version_element
    Tree.accepted.first.current_tree_version.instance_in_version(self)
  end

  def default_draft_tree_version_element
    Tree.accepted.first.default_draft_version.instance_in_version(self)
  end

  def accepted_concept?
    tve = accepted_tree_version_element
    tve.present? && !tve.tree_element.excluded
  end

  def excluded_concept?
    return nil unless accepted_concept?

    accepted_tree_version_element.tree_element.excluded
  end

  def in_any_tree?
    ::Tree::Element.where(instance_id: id).count > 0
  end

  def show_taxo?
    id == name.accepted_instance_id
  end

  def in_published_trees
    Instance
      .joins('INNER JOIN tree_element ON instance.id = tree_element.instance_id')
      .joins('JOIN tree_version_element tve ON tree_element.id = tve.tree_element_id')
      .joins('JOIN tree t ON tve.tree_version_id = t.current_tree_version_id')
      .where(id: id)
      .where('t.is_read_only = false')
      .select('instance.id, t.name AS name')
  end

  def in_workspace?(workspace)
    id == name.draft_instance_id(workspace)
  end

  def in_local_trees?
    in_local_trees.any?
  end

  def in_local_trees
    Tree.find_by_sql(["select t.* from tree_version_element tve join tree t on t.current_tree_version_id = tve.tree_version_id
  join tree_element te on tve.tree_element_id = te.id
where te.instance_id = ?", id])
  end

  def in_local_tree_names
    in_local_trees.collect do |tree|
      tree.name
    end.join(", ")
  end
end
