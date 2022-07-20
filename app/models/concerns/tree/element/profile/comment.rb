#
# Tree Element Profile 
module Concerns::Tree::Element::Profile::Comment extend ActiveSupport::Concern

  def comment
    return nil if profile.blank?

    profile[comment_key]
  end

  def comment?
    comment_key.present?
  end

  def comment_key
    tves.first.tree_version.tree.comment_key
  end

  def comment_value
    return nil if profile.blank?

    return nil if profile[comment_key].blank?

    profile[comment_key]["value"]
  end

  def add_profile_and_comment(comment, username)
    throw 'Profile already exists' unless profile.blank?

    comment = Tree::Element::Profile::Comment.new(username, comment)
    p = Hash.new
    p[comment_key] = comment.as_hash
    self.profile = p
    self.updated_by = username
    save!
  end

  def add_comment_to_profile(comment, username)
    throw 'No profile exists' if profile.blank?
    throw 'Profile comment already exists' unless profile[comment_key].blank?

    set_comment_in_profile(comment, username)
  end

  def change_comment_in_profile(comment_value, username)
    throw 'No profile exists' if profile.blank?
    throw 'Profile has no comment' if profile[comment_key].blank?

    changed_comment = self.comment
    changed_comment['value'] = comment_value
    changed_comment['updated_by'] = username
    changed_comment['updated_at'] = Time.now
    self.profile[comment_key] = changed_comment
    self.updated_by = username
    save!
  end

  def set_comment_in_profile(comment, username)
    comment = Tree::Element::Profile::Comment.new(username, comment)
    self.profile[comment_key] = comment.as_hash
    self.updated_by = username
    save!
  end

  def remove_comment(username)
    if distribution_value.blank?
      remove_profile(username)
    else
      remove_comment_leave_distribution(username)
    end
  end

  def remove_comment_leave_distribution(username)
    np = Hash.new
    np[distribution_key_for_insert] = distribution
    self.profile = np
    self.updated_by = username
    save!
  end
end
