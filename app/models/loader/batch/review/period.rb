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
# Loader BatchReview entity
class Loader::Batch::Review::Period < ActiveRecord::Base
  strip_attributes
  self.table_name = "batch_review_period"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  validates :start_date, presence: true
  validate :start_date_cannot_be_in_the_past
  #validate :start_date_cannot_be_changed_once_past, on: :update
  validate :end_date_cannot_be_in_the_past
  validate :end_date_must_be_after_start_date

  belongs_to :batch_review,
             class_name: "Loader::Batch::Review",
             foreign_key: "batch_review_id"
  alias_attribute :review, :batch_review

  has_many :batch_reviewers, class_name: "Loader::Batch::Reviewer", foreign_key: "batch_review_period_id"
  alias_attribute :reviewers, :batch_reviewers

  has_many :name_review_comments, class_name: "Loader::Name::Review::Comment", foreign_key: "review_period_id"
  alias_attribute :comments, :name_review_comments # deprecate - confusing with batch comments
  alias_attribute :name_comments, :name_review_comments

  has_many :names_with_comments, through: :name_review_comments, class_name: "Loader::Name", source: :loader_name

  attr_accessor :give_me_focus, :message

  def loader_name_comments(loader_name_id)
    comments.order(:created_at).collect.select {|x| x.loader_name_id == loader_name_id}
  end

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    'Review Period'
  end

  def allow_delete?
    true
  end

  def update_if_changed(params, username)
    self.name = params[:name]
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  # The table isn't in all schemas, so check it's there
  def self.exists?
    begin 
      BatchReviewPeriod.all.count
    end
    true
  rescue => e
    false
  end

  def start_date_cannot_be_in_the_past
    if will_save_change_to_start_date? 
      if start_date.present? && start_date < Date.today
        errors.add(:start_date, "can't be in the past")
      end
    end
  end

  def end_date_cannot_be_in_the_past
    if end_date.present? && end_date < Date.today
      errors.add(:end_date, "can't be changed to a past date")
    end
  end

  def end_date_must_be_after_start_date
    if end_date.present? && end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def start_date_cannot_be_changed_once_past
    if will_save_change_to_start_date? 
      db_record = BatchReviewPeriod.find(id)
      if db_record.start_date < Date.yesterday
        errors.add(:start_date, "can't be changed once the period has started")
      end
    end
  end

  def fresh?
    false
  end

  def record_type
    'BatchReviewPeriod'
  end

  def self.create(params, username)
    batch_review_period = self.new(params)
    if batch_review_period.save_with_username(username)
      batch_review_period
    else
      raise batch_review_period.errors.full_messages.first.to_s
    end
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    #set_defaults
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
    apply_start_date_if_changed(params)
    apply_end_date_if_changed(params) unless params['end_date(1i)'].blank?
    if has_changes_to_save?
      logger.debug("changes_to_save: #{changes_to_save.inspect}")
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def params_without_dates(params)
    h = Hash.new
    params.each do |key, val| 
      logger.debug("key: #{key}; val: #{val}")
      unless key =~ /start.date/ || key =~ /end.date/
        logger.debug("Adding key #{key} to hash")
        h[key] = val 
      end
    end
    h
  end

  def apply_start_date_if_changed(params)
    year = params['start_date(1i)']
    month = "%02d" % params['start_date(2i)']
    day = "%02d" % params['start_date(3i)']
    start_date_string = "#{year}-#{month}-#{day}"
    logger.debug("proposed start_date: #{start_date_string}")
    if start_date.to_s == start_date_string
      logger.debug('no start date change')
    else
      logger.debug('start date has changed')
      self.start_date = Date.parse(start_date_string)
    end
  end

  def apply_end_date_if_changed(params)
    year = params['end_date(1i)']
    month = "%02d" % params['end_date(2i)']
    day = "%02d" % params['end_date(3i)']
    end_date_string = "#{year}-#{month}-#{day}"
    logger.debug("proposed end_date: #{end_date_string}")
    if end_date.to_s == end_date_string
      logger.debug('no end_date date change')
    else
      logger.debug('end_date date has changed')
      self.end_date = Date.parse(end_date_string)
    end
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
    return 'future' if future?
    return 'past' if past?
    return 'active' if active?
  end

  def future?
    start_date > Time.now
  end

  def past?
    end_date.present? && end_date < Time.now
  end

  def active?
    start_date < Time.now &&
    (end_date.blank? || end_date > Time.now)
  end

  def reviewer?(username)
    reviewers.select {|r| r.user.name.downcase == username.downcase}.size > 0
  end

  def reviewer_id(username)
    reviewers.select {|r| r.user.name.downcase == username.downcase}.first.id
  end

  def finite?
    end_date.present?
  end
end
  
