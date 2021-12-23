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

  belongs_to :batch_review_period, class_name: "Loader::Batch::Review::Period", foreign_key: "batch_review_period_id"
  alias_attribute :period, :batch_review_period
  belongs_to :user_table, class_name: "UserTable", foreign_key: "user_id"
  alias_attribute :user, :user_table
  belongs_to :org 
  belongs_to :batch_review_role, class_name: "Loader::Batch::Review::Role" 
  alias_attribute :role, :batch_review_role
  has_many :name_review_comments, class_name: "Loader::Name::Review::Comment", foreign_key: "batch_reviewer_id"

  validates :user_id, presence: true
  validates :org_id, presence: true
  validates :batch_review_role_id, presence: true
  validates :batch_review_period_id, presence: true
  validates :user_id, uniqueness: { scope: :batch_review_period_id,
    message: "should only be added once per review period" }
  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    'Batch Reviewer'
  end

  def allow_delete?
    true
  end

  def name
    user.name
  end

  def full_name
    user.full_name
  end
  
  def self.create(params, username)
    batch_reviewer = self.new(params)
    if batch_reviewer.save_with_username(username)
      batch_reviewer
    else
      raise batch_reviewer.errors.full_messages.first.to_s
    end
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    #set_defaults
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
end
