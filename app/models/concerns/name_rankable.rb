# frozen_string_literal: true

# Name rank rules
module NameRankable
  extend ActiveSupport::Concern
  included do
    belongs_to :name_rank
  end

  def parent_rank_above?
    parent.present? &&
      parent.name_rank.present? &&
      name_rank.present? &&
      parent.name_rank.above?(name_rank)
  end

  def both_unranked?
    name_rank_id == parent.name_rank_id && name_rank.unranked?
  end

  # TODO: Boolean function shouldn't add error.
  def parent_rank_high_enough?
    return unless requires_parent? && requires_higher_ranked_parent?
    return if parent.blank? || parent_rank_above? || both_unranked?

    errors.add(:parent_id, "rank (#{parent.try('name_rank').try('name')}) \
                   must be higher than name rank (#{name_rank.try('name')})")
  end

  def rank_takes_parent?
    parent_name_rank.real_parent?
  end

  def parent_name_rank
    name_rank.parent
  end

  def ranks_up_to_next_major
    next_major = next_major_rank
    NameRank.where(["sort_order < :this_rank and sort_order >= :major_rank", {
                     this_rank: name_rank.sort_order, major_rank: next_major.sort_order
                   }])
  end

  def next_major_rank
    NameRank.where(["sort_order < :this_rank and major", { this_rank: name_rank.sort_order }])
            .order(:sort_order).reverse_order.first
  end
end
