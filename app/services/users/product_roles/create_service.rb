class Users::ProductRoles::CreateService < BaseService
  validate :user_exists, :product_role_exists

  attr_reader :user_product_role

  def initialize(user_id:, product_role_id:, username:, params: {})
    super(params)
    @product_role_id = product_role_id
    @username = username
    @user_id = user_id
    @user = User.find_by(id: user_id)
  end

  def execute
    return if invalid?

    add_product_role_to_user
    set_default_context unless errors.any?
  end

  private

  attr_reader :user

  def user_exists
    return if user.present?
    errors.add(:base, "User with ID #{@user_id} does not exist")
  end

  def product_role_exists
    return if Product::Role.exists?(@product_role_id)
    errors.add(:base, "Product role with ID #{@product_role_id} does not exist")
  end

  def add_product_role_to_user
    user_product_role = User::ProductRole.create({ user_id: @user_id, product_role_id: @product_role_id }, @username)
    @user_product_role = user_product_role
  rescue StandardError => e
    errors.add(:base, e.message)
  end

  def set_default_context
    return if user.default_product_context_id.present?
    return unless user_product_role

    product = user_product_role.product
    return unless product&.context_id

    user.default_product_context_id = product.context_id
    errors.add(:base, user.errors.full_messages.join(", ")) unless user.save
  end
end
