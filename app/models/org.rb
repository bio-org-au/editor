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
class Org < ActiveRecord::Base
  strip_attributes
  self.table_name = "org"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  has_many :batch_reviewers, class_name: "Loader::Batch::Reviewer", foreign_key: "org_id"

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

  def self.orgs_reviewer_can_vote_on_behalf_of(username)
    self.joins(batch_reviewers: :user_table)
        .where(["users.name = ?",username])
        .distinct
  end
end
