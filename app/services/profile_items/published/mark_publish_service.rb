class ProfileItems::Published::MarkPublishService < BaseService

  validate :draft_version_profile_item
  validate :already_published_profile_item

  attr_reader :profile_item, :new_profile_item

  def initialize(user:, profile_item:, params:)
    super(params)
    @user = user
    @profile_item = profile_item
  end

  def execute
    return unless valid?

    ActiveRecord::Base.transaction do
      publish_profile_item
      update_previous_profile_item
      raise ActiveRecord::Rollback if errors.any?
    end
  end

  private

  attr_reader :user, :params, :previous_published_profile_item

  def draft_version_profile_item
    return if profile_item.draft_version?
    errors.add(:base, "Profile item must be a draft version of a published item")
  end

  def already_published_profile_item
    return unless profile_item.published?
    errors.add(:base, "Profile item is already published")
  end

  def previous_profile_item
    @previous_profile_item ||= Profile::ProfileItem
      .by_product_item_config(profile_item.product_item_config)
      .where.not(is_draft: true)
      .order(published_date: :desc)
      .first
  end

  def publish_profile_item
    profile_item.tap do |item|
      item.is_draft = false
      item.published_date = Time.current
      item.current_user = user
    end
    profile_item.save
    return errors.merge!(profile_item.errors) if profile_item.errors.any?
  end

  def update_previous_profile_item
    return unless previous_profile_item

    previous_profile_item.update(end_date: profile_item.published_date)
    return errors.merge!(previous_profile_item.errors) if previous_profile_item.errors.any?
  end

end
