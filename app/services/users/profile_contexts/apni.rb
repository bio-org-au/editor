class Users::ProfileContexts::Apni < Users::ProfileContexts::Base
  
  def initialize(user)
    super
    @product = "APNI"
  end

  def profile_view_allowed?
    true
  end

  def instance_edit_allowed?
    user.groups.include?('v2-profile-instance-edit')
  end

  def copy_instance_allowed?
    true
  end

end