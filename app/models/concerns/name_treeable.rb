# frozen_string_literal: true

# Names can be in a classification tree
module NameTreeable
  extend ActiveSupport::Concern

  def accepted_tree_version_element
    Tree.accepted.first.current_tree_version.name_in_version(self)
  end

  def default_draft_tree_version_element
    Tree.accepted.first.default_draft_version.name_in_version(self)
  end

  def draft_instance_id(draft_version)
    return nil unless draft_version.present?

    tree_version_element = draft_version.name_in_version(self)
    return nil unless tree_version_element.present?

    tree_version_element.tree_element.instance.id
  end

  def draft_tree_version_element(draft_version)
    TreeVersion.find(draft_version.id).name_in_version(self)
  end

  def accepted_concept?
    tve = accepted_tree_version_element
    tve.present? && !tve.tree_element.excluded
  end

  def accepted_instance_id
    tve = accepted_tree_version_element
    tve.present? && tve.tree_element.instance_id
  end

  def excluded_concept?
    tve = accepted_tree_version_element
    tve.present? && tve.tree_element.excluded
  end

  def sub_tree_size(level = 0)
    @size_ = 0 if level.zero?
    @size_ ||= 0
    @size_ += 1
    level += 1
    children.each do |child|
      @size_ += child.sub_tree_size(level)
    end
    @size_
  end

  def refresh_tree
    @tally ||= 0
    @tally += refresh_constructed_name_fields
    children.each do |child|
      @tally += child.refresh_tree
    end
    just_second_children.each do |child|
      @tally += child.refresh_tree
    end
    @tally
  end

  def accepted_distribution
    if accepted_concept?
      accepted_tree_version_element.tree_element.distribution_value
    else
      ''
    end
  end

  def accepted_or_excluded_comment
    if accepted_concept?
      accepted_tree_version_element.tree_element.comment_value
    elsif excluded_concept?
      accepted_tree_version_element.tree_element.comment_value
    else
      ''
    end
  end
end
