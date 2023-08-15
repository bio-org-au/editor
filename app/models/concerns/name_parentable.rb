# frozen_string_literal: true

# Name scopes
module NameParentable
  extend ActiveSupport::Concern
  included do
    belongs_to :parent, class_name: "Name", foreign_key: "parent_id", optional: true
    has_many :children,
             class_name: "Name",
             foreign_key: "parent_id",
             dependent: :restrict_with_exception
    belongs_to :second_parent, optional: true,
                               class_name: "Name", foreign_key: "second_parent_id"
    has_many :second_children,
             class_name: "Name",
             foreign_key: "second_parent_id",
             dependent: :restrict_with_exception
    has_many :just_second_children,
             -> { where "parent_id != second_parent_id" },
             class_name: "Name", foreign_key: "second_parent_id",
             dependent: :restrict_with_exception
  end

  def requires_parent?
    name_category.requires_parent_1? &&
      name_rank.present? &&
      name_rank.below_family?
  end

  def requires_parent_1?
    requires_parent?
  end

  def takes_parent_1?
    name_category.max_parents_allowed > 0
  end

  def takes_parent_2?
    name_category.max_parents_allowed > 1
  end

  def requires_parent_2?
    name_category.requires_parent_2?
  end

  def takes_hybrid_scoped_parent?
    name_category.takes_hybrid_scoped_parent?
  end

  def takes_cultivar_scoped_parent?
    name_category.takes_cultivar_scoped_parent?
  end

  def parent_rule
    name_category.parent_1_help_text
  end

  def second_parent_rule
    name_category.parent_2_help_text
  end

  def has_parent?
    parent_id.present?
  end

  def has_second_parent?
    second_parent.present?
  end

  def without_parent?
    !has_parent?
  end

  def needs_second_parent?
    hybrid? && !has_second_parent?
  end

  def descendents
    Name.all_children(id)
  end

  def combined_children
    Name.all_children(id)
  end
end
