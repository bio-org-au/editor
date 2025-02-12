class Users::ProfileContexts::FoaAccess < Users::ProfileContexts::BaseAccess
  
  def initialize(user)
    super
    @product = "FOA"
  end

  def viewer?
    true
  end
  
  def editor?
    instance_editor?
  end

  def instance_editor?
    user.groups.include?('v2-profile-instance-edit')
  end
end