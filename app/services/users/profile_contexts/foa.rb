class Users::ProfileContexts::Foa < Users::ProfileContexts::Base

  def initialize(user)
    super
    @product = "FOA"
  end

  def profile_view_allowed?
    true
  end
  
  def profile_edit_allowed?
    instance_edit_allowed?
  end

  def instance_edit_allowed?
    user.groups.include?('v2-profile-instance-edit')
  end

  def copy_instance_allowed?
    true
  end

  #
  # Tabs
  #
  def copy_instance_tab(instance, row_type=nil)
    "tab_copy_to_new_profile_v2" unless instance.draft
  end

  def unpublished_citation_tab(instance)
    "tab_unpublished_citation_for_profile_v2" if instance.draft
  end

end