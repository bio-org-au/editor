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
class Loader::Batch::Review < ActiveRecord::Base
  strip_attributes
  self.table_name = "batch_review"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  validates :name, presence: true
  validates :name, uniqueness: { scope: :loader_batch_id,
                                 message: "of the Review must be unique within its Batch" }
  before_destroy :abort_if_review_periods

  belongs_to :loader_batch, class_name: "Loader::Batch", foreign_key: "loader_batch_id"
  alias_method :batch, :loader_batch

  has_many :batch_review_periods, class_name: "Loader::Batch::Review::Period", foreign_key: "batch_review_id"
  alias_method :periods, :batch_review_periods
  alias_method :review_periods, :batch_review_periods

  has_many :batch_reviewers, class_name: "Loader::Batch::Reviewer", foreign_key: "batch_review_id"
  alias_method :reviewers, :batch_reviewers

  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    "Batch Review"
  end

  def allow_delete?
    !review_periods.exists?
  end

  def active_periods
    review_periods.active
  end

  def update_if_changed(params, username)
    self.name = params[:name]
    self.allow_voting = params[:allow_voting]
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def name_in_context
    "#{batch.name} #{name}"
  end

  def allow_voting_to_words
    allow_voting ? 'allowed' : 'not allowed'
  end

  def reviewer?(username)
    reviewers.select { |r| r.user.user_name.downcase == username.downcase }.size > 0
  end

  def reviewer_id(username)
    reviewers.select { |r| r.user.user_name.downcase == username.downcase }.first.id
  end

  private

  def abort_if_review_periods
    return unless review_periods.exists?

    throw "Review cannot be deleted because it has review periods"
  end
end
