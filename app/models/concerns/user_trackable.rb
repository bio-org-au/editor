# app/models/concerns/track_user.rb
module UserTrackable
  extend ActiveSupport::Concern

  included do
    attr_accessor :current_user # Define an instance-level accessor for current_user
    before_create :set_created_by, if: :current_user
    before_save :set_updated_by, if: :current_user
  end

  private

  def set_created_by
    self.created_by ||= current_user&.user_name if respond_to?(:created_by)
  end

  def set_updated_by
    self.updated_by = current_user&.user_name if respond_to?(:updated_by)
  end
end
