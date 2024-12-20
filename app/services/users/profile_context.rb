class Users::ProfileContext

  PROFILE_CONTEXTS = {
    apni:    Users::ProfileContexts::Apni,
    foa:     Users::ProfileContexts::Foa,
    default: Users::ProfileContexts::Base,
  }.freeze

  private_constant :PROFILE_CONTEXTS

  attr_reader :context

  def initialize(user)
    @user = user
    @context = get_user_context
  end

  private

  attr_reader :user

  def get_user_context
    return PROFILE_CONTEXTS[:default].new(user) unless Rails.configuration.try('profile_v2_aware')

    if user.groups.include?('foa') || user.groups.include?('foa-context-group')
      PROFILE_CONTEXTS[:foa].new(user)
    else
      PROFILE_CONTEXTS[:apni].new(user)
    end
  end
end