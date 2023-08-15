# frozen_string_literal: true

# Names can be in a classification tree
module NameFamilyable
  extend ActiveSupport::Concern

  def requires_family?
    name_rank.below_family? && name_category.requires_family
  end

  def family_members
    Name.where(["family_id = ?", id])
  end
end
