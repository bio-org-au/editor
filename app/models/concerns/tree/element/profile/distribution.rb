#
# Tree Element Profile
module Tree::Element::Profile::Distribution
  extend ActiveSupport::Concern
  def distribution
    return nil if profile.blank?

    profile[distribution_key]
  end

  def distribution_value
    return nil if profile.blank?

    return nil if profile[distribution_key_for_insert].blank?

    profile[distribution_key]["value"]
  end

  def distribution?
    distribution_key.present?
  end

  def distribution_key
    profile_key(/Dist/)
  end

  def distribution_key_for_insert
    tree_version_elements.first.tree_version.tree.distribution_key
  end

  def dist_options_disabled
    disabled_options = []
    all = DistEntry.all.includes(:dist_region)
    for n in tede_dist_entries.collect(&:region)
      disabled_options.concat(all.find_all do |opt|
                                opt.dist_region.name == n
                              end.collect(&:display))
    end
    disabled_options
  end

  def current_dist_options
    tede_dist_entries.collect(&:display)
  end

  def construct_distribution_string
    tede_dist_entries
      .sort { |a, b| a.dist_region.sort_order <=> b.dist_region.sort_order }
      .collect(&:entry)
      .join(", ")
  end

  def distribution_as_arr
    return [] if distribution_value.nil?

    distribution_value.split(",").collect { |val| val.strip }
  end
end
