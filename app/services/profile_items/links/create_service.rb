class ProfileItems::Links::CreateService < BaseService

  validate :published_profile_item

  attr_reader :profile_item

  def initialize(instance:, user:, source_profile_item:, params:)
    super(params)
    @instance = instance
    @user = user
    @source_profile_item = source_profile_item
    @profile_item = Profile::ProfileItem.new(
      statement_type: Profile::ProfileItem::STATEMENT_TYPES[:link],
      source_profile_item_id: source_profile_item.id,
      is_draft: true,
      instance_id: instance.id,
      profile_text_id: source_profile_item.profile_text_id,
      product_item_config_id: source_profile_item.product_item_config_id,
    )
  end

  def execute
    return unless valid?

    profile_item.current_user = user
    profile_item.save

    return errors.merge!(profile_item.errors) if profile_item.errors.any?

    profile_item.reload
  end

  private

  attr_reader :instance, :source_profile_item, :params, :user

  def published_profile_item
    return unless source_profile_item.is_draft
    errors.add(:base, "Profile item must be published before linking")
  end
end
