class Users::ProfileContexts::ApniAccess < Users::ProfileContexts::BaseAccess
  
  def initialize(user)
    super
    @product = "APNI"
  end

  # Add custom methods

  def viewer?
    true
  end

  def instance_editor?
    user.groups.include?('v2-profile-instance-edit')
  end
end