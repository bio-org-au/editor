#
# Tree Element Profile 
module Tree::Element::Profile::Distribution::LowLevelOps extend ActiveSupport::Concern

  def add_profile_and_distribution(new_dist, username)
    throw 'Profile already exists' unless profile.blank?

    dist = Tree::Element::Profile::DistributionObject.new(new_dist, username)
    p = Hash.new
    p[distribution_key_for_insert] = dist.as_hash
    self.profile = p
    self.updated_by = username
    save!
  end

  def add_validated_dist_to_profile(new_dist, username)
    throw 'Profile expected.' if profile.blank?

    throw 'Profile distribution not expected.' unless profile[distribution_key_for_insert].blank?

    dist_object = Tree::Element::Profile::DistributionObject.new(new_dist, username)
    self.profile[distribution_key_for_insert] = dist_object.as_hash
    self.updated_by = username
    save!
  end

  def change_existing_distribution_in_profile(new_dist, username)
    throw 'Profile expected.' if profile.blank?

    throw 'Profile distribution expected' if profile[distribution_key_for_insert].blank?

    dist_object = distribution
    dist_object["value"] = new_dist
    dist_object['updated_at'] = Time.now
    dist_object['updated_by'] = username
    self.profile[distribution_key_for_insert] = dist_object
    self.updated_by = username
    save!
  end

  def remove_distribution(username)
    if comment_value.blank?
      remove_profile(username)
    else
      remove_distribution_leave_comment(username)
    end
  end

  def remove_distribution_leave_comment(username)
    np = Hash.new
    np[comment_key] = comment
    self.profile = np
    self.updated_by = username
    save!
  end
end
