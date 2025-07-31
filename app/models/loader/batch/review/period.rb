# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Loader Batch Review Period entity
class Loader::Batch::Review::Period < ActiveRecord::Base
  include DigestEndDate
  strip_attributes
  self.table_name = "batch_review_period"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  validates :name, presence: true,
                   uniqueness: { scope: :batch_review_id, message: "has been used for another period in the same batch review" }
  validates :start_date, presence: true
  validate :start_date_cannot_be_in_the_past
  validates :start_date,
            uniqueness: { scope: :batch_review_id,
                          message: "has been used for another period in the same batch review" }
  # validate :start_date_cannot_be_changed_once_past, on: :update

  validate :end_date_cannot_be_in_the_past
  validate :end_date_must_be_after_start_date
  before_destroy :abort_if_comments

  belongs_to :batch_review,
             class_name: "Loader::Batch::Review",
             foreign_key: "batch_review_id"
  alias_method :review, :batch_review

  has_many :name_review_comments, class_name: "Loader::Name::Review::Comment", foreign_key: "batch_review_period_id"
  alias_method :comments, :name_review_comments # deprecate - confusing with batch comments
  alias_method :name_comments, :name_review_comments

  has_many :names_with_comments, through: :name_review_comments, class_name: "Loader::Name", source: :loader_name

  attr_accessor :give_me_focus, :message

  scope :active, -> { 
    where("start_date <= ?", Time.zone.today)
    .where("end_date IS NULL OR end_date >= ?", Time.zone.today)
  }

  def loader_name_comments(loader_name_id, scope = "unrestricted")
    if scope == "unrestricted"
      return comments.order(:created_at).collect.select do |x|
               x.loader_name_id == loader_name_id
             end
    end

    comments.order(:created_at).collect.select do |x|
      x.loader_name_id == loader_name_id
    end.select { |x| x.context.downcase == scope.downcase }
  end

  def fresh?
    true # created_at > 1.hour.ago
  end

  def display_as
    "Review Period"
  end

  def allow_delete?
    !name_comments.exists?
  end

  # The table isn't in all schemas, so check it's there
  def self.exists?
    BatchReviewPeriod.all.count

    true
  rescue StandardError => e
    false
  end

  def start_date_cannot_be_in_the_past
    return unless will_save_change_to_start_date?
    return unless start_date.present? && start_date < Date.today

    errors.add(:start_date, "cannot be in the past")
  end

  def end_date_cannot_be_in_the_past
    return unless end_date.present? && end_date < Date.today

    errors.add(:end_date, "cannot be changed to a past date")
  end

  def end_date_must_be_after_start_date
    return unless end_date.present? && end_date < start_date

    errors.add(:end_date, "must be after start date")
  end

  def start_date_cannot_be_changed_once_past
    return unless will_save_change_to_start_date?

    db_record = BatchReviewPeriod.find(id)
    return unless db_record.start_date < Date.yesterday

    errors.add(:start_date, "cannot be changed once the period has started")
  end

  def record_type
    "BatchReviewPeriod"
  end

  def self.create(params, username)
    batch_review_period = new(params)
    raise batch_review_period.errors.full_messages.first.to_s unless batch_review_period.save_with_username(username)

    batch_review_period
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    # set_defaults
    save
  end

  # Added code to handle start and end dates because using the raw
  # params was giving false positives for date changes - not sure why
  #
  # sample raw parameters look like this:
  # {"start_date(3i)"=>"14", "start_date(2i)"=>"8", "start_date(1i)"=>"2020",
  # "end_date(3i)"=>"14", "end_date(2i)"=>"9", "end_date(1i)"=>"2020"
  #
  def update_if_changed(params, username)
    assign_attributes(params_without_dates(params))
    assign_start_date_if_changed(params)
    assign_end_date_if_changed(params)
    if has_changes_to_save?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def params_without_dates(params)
    h = {}
    params.each do |key, val|
      h[key] = val unless key =~ /start.date/ || key =~ /end.date/
    end
  end

  # The start_date is required so nil values are prevented before here.
  #
  # We do have to handle the case of dates like 30-Feb-2025 being entered.
  #
  def assign_start_date_if_changed(params)
    year = params["start_date(1i)"]
    month = format("%02d", params["start_date(2i)"])
    day = format("%02d", params["start_date(3i)"])
    date_s = "#{year}-#{month}-#{day}"
    self.start_date = Date.parse(date_s) unless start_date.to_s == date_s
  rescue Date::Error => e
    message = "Invalid start date: #{date_s}"
    logger.error(e.to_s)
    raise message
  end

  def can_be_deleted?
    true # for now
  end

  def start_time
    start_date
  end

  def end_time
    end_date
  end

  def status
    return "future" if future?
    return "past" if past?

    "active" if active?
  end

  # Comparison needs to be TZ neutral
  def future?
    start_date > Time.zone.today
  end

  # Comparison needs to be TZ neutral
  # We get PG to convert the date stored in db to the Rails TZ
  def past?
    return false unless end_date.present?

    end_date < Time.zone.today
  end

  def active?
    !future? && !past?
  end

  def finite?
    end_date.present?
  end

  private

  def abort_if_comments
    return unless name_comments.exists?

    throw "Cannot delete period because it has comments"
  end
end
