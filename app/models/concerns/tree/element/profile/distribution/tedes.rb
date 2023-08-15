#
# Tree Element Profile
module Tree::Element::Profile::Distribution::Tedes
  extend ActiveSupport::Concern
  def apply_string_to_tedes
    add_missing_tedes
    remove_excess_tedes
  end

  def missing_tedes
    distribution_as_arr - tede_entries_arr
  end

  def add_missing_tedes
    missing_tedes.each { |value| add_tede(value) }
  end

  def add_tede(value)
    tede = Tree::Element::DistributionEntry.new
    tede.tree_element_id = id
    tede.dist_entry_id = DistEntry.id_for_display(value)
    tede.updated_by = @current_user&.username || "unknown"
    tede.save!
  rescue StandardError => e
    Rails.logger.error("tedes error with value: #{value}: #{e}")
    raise
  end

  def excess_tedes
    tede_entries_arr - distribution_as_arr
  end

  def remove_excess_tedes
    excess_tedes.each { |value| remove_tede(value) }
  end

  def remove_tede(value)
    tede = Tree::Element::DistributionEntry
           .find_by(tree_element_id: id,
                    dist_entry_id: DistEntry.id_for_display(value))
    tede.delete
  end

  # Sorted correctly
  def tede_entries_arr
    tede_dist_entries.sort { |x, y| x.sort_order <=> y.sort_order }
                     .collect { |x| x.display }
  end

  def delete_tedes
    tede = Tree::Element::DistributionEntry
           .where(tree_element_id: id).each do |tede|
      tede.delete
    end
  end
end
