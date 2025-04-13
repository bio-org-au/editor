# Help display profile_item information.
module Profile::ProfileItemsHelper
  def sourced_in_profile_items_info(profile_item, action: :delete)
    return unless profile_item.sourced_in_profile_items.present?

    count = profile_item.sourced_in_profile_items.count
    action_message = ""
    action_message = "You cannot delete this profile item" if action == :delete
    content_tag(:div, style: "padding: 10px;") do
      "#{action_message}. This item is cited by #{ActionController::Base.helpers.pluralize(count, 'other profile item')}."
    end
  end
end
