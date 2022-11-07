#
#
#
#
#
# Tree Element Profile 
module Tree::Element::Profile extend ActiveSupport::Concern

  def profile_value(key_string)
    key = profile_key(key_string)
    if key
      profile[key]["value"]
    else
      ""
    end
  end

  def profile_key(pkey)
    return nil unless profile.present?

    if pkey.is_a? String then
      profile.keys.find {|key| key == pkey}
    elsif pkey.is_a? Regexp then
      profile.keys.find {|key| key =~ pkey}
    else 
      raise 'Not a string or a regexp....'
    end
  end

  def update_comment(comment_param, username)
    if comment_param.blank?
      return apply_blank_comment(username)
    else
      return apply_non_blank_comment(comment_param, username)
    end
    return message, refresh || false
  end

  def apply_blank_comment(username)
    refresh = false
    if profile.blank?
      message = 'Empty comment for empty profile - nothing to do'
    elsif comment_value.blank?
      message = 'No change to comment'
    else
      remove_comment(username)
      message = 'Comment removed'
      refresh = true
    end
    return message, refresh
  end

  def apply_non_blank_comment(comment_param, username)
    refresh = true
    case
    when comment_value.blank?
      add_comment(comment_param, username) 
      message = 'Comment added'
    when comment_value != comment_param
      change_comment_in_profile(comment_param, username)
      message = 'Comment changed'
    else
      message = 'No change to comment'
      refresh = false
    end
    return message, refresh
  end

  def add_comment(comment_param, username)
    if profile.blank?
      add_profile_and_comment(comment_param, username) 
    elsif comment_value.blank?
      add_comment_to_profile(comment_param, username)
    end
    message = "Comment added"
    refresh = true
    return message, refresh || false
  end

  def update_distribution(dist_param, username)
    message, refresh = '', false
    if excluded?
      message = "We don't allow changes to distribution for excluded taxa"
    else
      message, refresh = 
        transaction_for_update_accepted_distribution(dist_param, username)
    end
    return message, refresh
  end

  def transaction_for_update_accepted_distribution(dist_param, username)
    message, refresh = '', false
    ActiveRecord::Base.transaction do
      message, refresh = update_accepted_distribution(dist_param, username)
    rescue => e
      Rails.logger.error("Rolling back transaction in update_distribution")
      Rails.logger.error(e.to_s)
      message = "Error: #{e.to_s}"
      refresh = false
      raise ActiveRecord::Rollback
    end
    return message, refresh
  end

  def update_accepted_distribution(dist_param, username)
    if dist_param.blank?
      return update_dist_with_blank_param(username)
    else # dist param non-blank
      return update_dist_with_non_blank_param(dist_param, username)
    end
  end
  
  def remove_profile(username)
    self.profile = nil
    self.updated_by = username
    save!
  end
end
