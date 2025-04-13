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
# Loader BatchReviewer entity
class Loader::Batch::Reviewer < ActiveRecord::Base
  strip_attributes
  self.table_name = "batch_reviewer"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :batch_review, class_name: "Loader::Batch::Review", foreign_key: "batch_review_id"
  belongs_to :user, foreign_key: "user_id"
  belongs_to :org, optional: true
  belongs_to :batch_review_role, class_name: "Loader::Batch::Review::Role"
  alias_method :role, :batch_review_role
  has_many :name_review_comments, class_name: "Loader::Name::Review::Comment", foreign_key: "batch_reviewer_id" do
    def by_review_period(batch_review_period_id)
      where(batch_review_period_id: batch_review_period_id)
    end
    def by_review(batch_review_id)
      where(['batch_review_period_id in (select id from batch_review_period brp where brp.batch_review_id = ?)', batch_review_id])
    end
  end

  validates :user_id, presence: true
  validates :batch_review_role_id, presence: true
  validates :batch_review_id, presence: true
  validates :user_id, uniqueness: { scope: :batch_review_id,
                                    message: "should only be added once per review" }
  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    "Batch Reviewer"
  end

  def allow_delete?
    true
  end

  def name
    user.user_name
  end

  def full_name
    user.full_name
  end

  def self.create(params, username)
    batch_reviewer = new(params)
    raise batch_reviewer.errors.full_messages.first.to_s unless batch_reviewer.save_with_username(username)

    batch_reviewer
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
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

  def self.batch_reviewers_for_org_username_batch_review(org, username, batch_review)
    self.where(org_id: org.id)
        .joins(:user)
        .where(["users.user_name = ?", username])
        .joins(batch_review_period: :batch_review)
        .where(["batch_review.loader_batch_id = ?", batch_review.loader_batch_id])
        .distinct
  end

  def self.username_to_reviewers_for_review(username, review)
    Loader::Batch::Reviewer.joins([:user, :batch_review])
                           .where('users.user_name': username)
                           .where('batch_review.id': review.id)
  end

end
