class ProfileItems::Published::CreateNewVersionService < BaseService

  validate :published_profile_item
  validate :any_draft_profile_items

  attr_reader :profile_item, :new_profile_item

  def initialize(instance:, user:, profile_item:, params:)
    super(params)
    @instance = instance
    @user = user
    @profile_item = profile_item
    @product_item_config = profile_item.product_item_config
    @new_profile_item = nil
  end

  def execute
    return unless valid?

    ActiveRecord::Base.transaction do
      copy_profile_item_as_draft
      copy_profile_text
      copy_profile_item_annotation
      copy_profile_item_references
      raise ActiveRecord::Rollback if errors.any?
    end
  end

  private

  attr_reader :instance, :params, :user, :product_item_config

  def published_profile_item
    return unless profile_item.is_draft
    errors.add(:base, "Profile item must be published before creating a new version")
  end

  def any_draft_profile_items
    return unless instance
      .profile_items
      .drafts
      .by_product_item_config(product_item_config)
      .exists?

    errors.add(:base, "There is still a draft profile item for this product item config")
  end

  def copy_profile_item_as_draft
    @new_profile_item = profile_item.dup
    new_profile_item.is_draft = true
    new_profile_item.published_date = nil
    new_profile_item.created_by = user.user_name
    new_profile_item.updated_by = user.user_name
    new_profile_item.save

    return errors.merge!(new_profile_item.errors) if new_profile_item.errors.any?

    new_profile_item.reload
  end

  def copy_profile_text
    new_profile_text = profile_item.profile_text.dup
    new_profile_text.current_user = user
    new_profile_text.save

    return errors.merge!(new_profile_text.errors) if new_profile_text.errors.any?

    @new_profile_item.profile_text = new_profile_text
    @new_profile_item.save

    return errors.merge!(@new_profile_item.errors) if @new_profile_item.errors.any?
  end

  def copy_profile_item_annotation
    return unless profile_item.profile_item_annotation

    new_profile_item_annotation = profile_item.profile_item_annotation.dup
    new_profile_item_annotation.current_user = user
    new_profile_item_annotation.profile_item_id = new_profile_item.id
    new_profile_item_annotation.save

    return errors.merge!(new_profile_item_annotation.errors) if new_profile_item_annotation.errors.any?
  end

  def copy_profile_item_references
    return if profile_item.profile_item_references.blank?

    profile_item.profile_item_references.each do |profile_item_reference|
      new_profile_item_reference = Profile::ProfileItemReference.new(
        profile_item_reference
          .attributes
          .except("profile_item_id", "created_by", "updated_by", "created_at", "updated_at")
      )
      new_profile_item_reference.profile_item_id = new_profile_item.id
      new_profile_item_reference.current_user = user
      new_profile_item_reference.annotation = "Modified from."
      new_profile_item_reference.save

      errors.merge!(new_profile_item_reference.errors) if new_profile_item_reference.errors.any?
    end
  end

end
