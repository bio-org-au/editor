class Users::ProfileContexts::FoaAccess < Users::ProfileContexts::BaseAccess

  def initialize(user)
    super
    @product = Users::ProfileContexts::BaseAccess::PRODUCTS[:foa]
  end

  def profile_view_allowed?
    true
  end
  
  def profile_edit_allowed?
    user.groups.include?('v2-profile-edit')
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
end