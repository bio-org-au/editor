# frozen_string_literal: true

# Name scopes
module AuditScopable
  extend ActiveSupport::Concern
  included do
    scope :created_n_days_ago,
          ->(n) { where("current_date - created_at::date = ?", n) }
    scope :updated_n_days_ago,
          ->(n) { where("current_date - updated_at::date = ?", n) }
    scope :xchanged_n_days_ago,
          (lambda do |n|
             where(["current_date - created_at::date = ? or
                   current_date - updated_at::date = ?", n, n])
           end)
    scope :created_in_the_last_n_days,
          ->(n) { where("current_date - created_at::date < ?", n) }
    scope :updated_in_the_last_n_days,
          ->(n) { where("current_date - updated_at::date < ?", n) }
    scope :changed_in_the_last_n_days,
          (lambda do |n|
             where(["current_date - created_at::date < ? or
                   current_date - updated_at::date < ?", n, n])
           end)
  end

  def fresh?
    created_at > 1.hour.ago
  end
end
