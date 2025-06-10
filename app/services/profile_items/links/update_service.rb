class ProfileItems::Links::UpdateService < BaseService

  validate :draft_profile_item

  attr_reader :profile_item, :profile_text

  def initialize(user:, profile_item:, params:)
    super(params)
    @user = user
    @profile_item = profile_item
    @source_profile_item = profile_item.source_profile_item
    @profile_item_references = []
  end

  def execute
    return unless valid?

    ActiveRecord::Base.transaction do
      create_profile_text
      convert_profile_item_to_fact
      create_profile_item_references
      raise ActiveRecord::Rollback if errors.any?
    end
  end

  private

  attr_reader :user, :source_profile_item, :profile_item_references

  def draft_profile_item
    return if profile_item.is_draft
    errors.add(:base, "Cannot update a published profile item")
  end

  def create_profile_text
    @profile_text = Profile::ProfileText.new(value_md: profile_item.profile_text.value_md, value: profile_item.profile_text.value)
    @profile_text.current_user = user
    @profile_text.save
    errors.merge!(@profile_text.errors) if @profile_text.errors.any?
  end

  def create_profile_item_references
    return if source_profile_item&.profile_item_references.blank?

    @profile_item_references = source_profile_item.profile_item_references.map do |profile_item_reference|
      new_profile_item_reference = Profile::ProfileItemReference.new(
        profile_item_reference
          .attributes
          .except("profile_item_id", "created_by", "updated_by", "created_at", "updated_at")
      )
      new_profile_item_reference.profile_item_id = profile_item.id
      new_profile_item_reference.current_user = user
      new_profile_item_reference.annotation = "Modified from."
      new_profile_item_reference.save
      errors.merge!(new_profile_item_reference.errors) if new_profile_item_reference.errors.any?

      new_profile_item_reference
    end
  end

  def convert_profile_item_to_fact
    profile_item.current_user = user
    profile_item.assign_attributes(
      source_profile_item_id: nil,
      statement_type: Profile::ProfileItem::STATEMENT_TYPES[:fact],
      profile_text_id: profile_text.id
    )
    profile_item.save
    errors.merge!(profile_item.errors) if profile_item.errors.any?
  end
end
