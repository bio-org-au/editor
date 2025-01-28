class Users::ProfileContexts::Foa < Users::ProfileContexts::Base

  def initialize(user)
    super
    @product = "FOA"
  end

  def profile_view_allowed?
    true
  end

  def profile_edit_allowed?
    user.groups.include?('foa')
  end

  def instance_edit_allowed?
    user.groups.include?('v2-profile-instance-edit')
  end

  def draft_instance_action_allowed?
    user.groups.include?('foa-context-group')
  end

  #
  # Tabs
  #
  def copy_instance_tab(instance, row_type=nil)
    if draft_instance_action_allowed?
      "tab_copy_to_new_profile_v2" unless instance.draft
    else
      super
    end
  end

  def unpublished_citation_tab(instance)
    if draft_instance_action_allowed?
      "tab_unpublished_citation_for_profile_v2" if instance.draft && instance.secondary_reference?
    else
      super
    end
  end

  def synonymy_tab(instance)
    if draft_instance_action_allowed?
      "tab_synonymy_for_profile_v2" if instance.draft && instance.secondary_reference?
    else
      super
    end
  end

end
