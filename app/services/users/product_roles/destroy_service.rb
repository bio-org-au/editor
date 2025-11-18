class Users::ProductRoles::DestroyService < BaseService
  attr_reader :user_product_role

  MAIN_CONTEXT_ID = 1

  def initialize(user_product_role:, params: {})
    super(params)
    @user_product_role = user_product_role
  end

  def execute
    delete_user_product_role
    set_default_context
  end

  private

  def delete_user_product_role
    unless user_product_role.destroy
      errors.add(:base, user_product_role.errors.full_messages.join(", "))
    end
  end

  def set_default_context
    return if errors.any?

    user = user_product_role.user
    remaining_products = user.user_product_roles.reload
      .includes(:product)
      .map(&:product)
      .compact

    if remaining_products.any?
      user.default_product_context_id = remaining_products.first.context_id
    else
      user.default_product_context_id = MAIN_CONTEXT_ID
    end
    user.save

    errors.add(:base, user.errors.full_messages.join(", ")) if user.errors.any?
  rescue StandardError => e
    errors.add(:base, e.message)
  end
end
