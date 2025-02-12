class Users::ProfileContexts::BaseAccess
  
  attr_reader :user, :product

  def initialize(user)
    @user = user
    @product = "unknown"
    @logger = Rails.logger
  end

  def viewer?
    false
  end

  def editor?
    false
  end

  def instance_editor?
    false
  end

  def method_missing(method_name, *args, &block)
    if respond_to_missing?(method_name)
      super
    else
      @logger.warn("Undefined method `#{method_name}` called on #{self.class.name}")
      nil
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    false
  end
end