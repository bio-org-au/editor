#
#
#
#
#
# Tree Element Profile 
module Tree::Element::Profile::Distribution::UpdateAccepted extend ActiveSupport::Concern

  def update_dist_with_non_blank_param(dist_param, username)
    throw 'Expecting non-blank distribution' if dist_param.nil?

    case
    when profile.blank?
      return add_dist_to_empty_profile(dist_param, username)
    when distribution_value.blank?
      return add_dist_to_profile(dist_param, username)
    when distribution_value != dist_param
      return change_dist(dist_param, username)
    else 
      return "No change to distribution", false
    end
  end

  def update_dist_with_blank_param(username)
    refresh = false
    case 
    when profile.blank?
      message = 'Empty distribution for empty profile - nothing to do'
    when distribution_value.blank?
      message = 'No distribution change'
    else
      remove_distribution(username)
      te = Tree::Element.find(self.id)
      te.delete_tedes
      message = 'Distribution removed'
      refresh = true
    end
    return message, refresh
  end

  def add_dist_to_profile(dist_param, username)
    new_cleaned = Tree::Element.cleanup_distribution_string(dist_param)
    Tree::Element.validate_distribution_string(new_cleaned)
    add_validated_dist_to_profile(new_cleaned, username)
    te = Tree::Element.find(self.id)
    te.apply_string_to_tedes
    return 'Distribution added', true
  end

  def add_dist_to_empty_profile(dist_param, username)
    throw 'dist_param must not be nil!' if dist_param.nil?

    new_cleaned = Tree::Element.cleanup_distribution_string(dist_param)
    Tree::Element.validate_distribution_string(new_cleaned)
    throw 'clean dist_param must not be nil!' if new_cleaned.nil?

    add_profile_and_distribution(new_cleaned, username)
    te = Tree::Element.find(self.id)
    te.apply_string_to_tedes
    return 'Distribution added to a fresh profile', true
  end

  def change_dist(dist_param, username)
    message = 'Distribution has changed'
    new_cleaned = Tree::Element.cleanup_distribution_string(dist_param)
    if new_cleaned == distribution_value
      message =
        'No change in standardardised format of accepted taxon distribution'
    else
      Tree::Element.validate_distribution_string(new_cleaned)
      change_existing_distribution_in_profile(new_cleaned, username)
      te = Tree::Element.find(self.id)
      te.apply_string_to_tedes
      refresh = true
      message = 'Distribution changed'
    end
    return message, refresh
  end
end
