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
# Loader Org entity
# == Schema Information
#
# Table name: org
#
#  id           :bigint           not null, primary key
#  abbrev       :string(30)       not null
#  created_by   :string(50)       not null
#  deprecated   :boolean          default(FALSE), not null
#  lock_version :bigint           default(0), not null
#  name         :string(100)      not null
#  no_org       :boolean          default(FALSE), not null
#  updated_by   :string(50)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#
# Indexes
#
#  org_abbrev_key  (abbrev) UNIQUE
#  org_name_key    (name) UNIQUE
#
class Org < ActiveRecord::Base
  strip_attributes
  self.table_name = "org"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  has_many :batch_reviewers, class_name: "Loader::Batch::Reviewer", foreign_key: "org_id"
  has_many :name_review_votes, class_name: "Loader::Name::Review::Vote", foreign_key: "org_id"

  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    "Organisation"
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

  def self.xorgs_reviewer_can_vote_on_behalf_of_in_a_review(username, review)
    Org.joins(batch_reviewers: [:user, :batch_review_period])
       .where('users.user_name': username)
      .where('batch_review_period.batch_review_id': review.id)
  end

  def self.yorgs_reviewer_can_vote_on_behalf_of_in_a_review(reviewer)
    Org.joins(batch_reviewers: [:user, :batch_review_period])
       .where('users.user_name': username)
      .where('batch_review_period.batch_review_id': review.id)
  end

  def can_vote_in_review(review)
    batch_reviewers.where(batch_review_id: review.id)
  end

  def user_as_reviewer_for_review(username, review)
    can_vote_in_review(review).where(user_id: User.where(user_name: 'gbentham')).first
  end
end
