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
# Loader Usertable entity
#
# Called UserTable to distinguish from the pre-existing user model which is
# used for authenticatio/authorisation.  This model is for the users table
# created during work on the batch loader and batch review subsystem.
# == Schema Information
#
# Table name: users
#
#  id           :bigint           not null, primary key
#  created_by   :string(50)       not null
#  family_name  :string(60)       not null
#  given_name   :string(60)
#  lock_version :bigint           default(0), not null
#  name         :string(30)       not null
#  updated_by   :string(50)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#
# Indexes
#
#  users_name_key  (name) UNIQUE
#
class UserTable < ActiveRecord::Base
  strip_attributes
  self.table_name = "users"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  has_many :batch_reviewers, class_name: "Loader::Batch::Reviewer", foreign_key: :user_id

  # Note, the PK for the users table is the id column.
  # That appears as user_id as a foreign key.
  # The user's login id is in the column name - called that to avoid
  # confusion with the FK user_id or with the PK id.
  def userid
    name
  end

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    "User"
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

  def full_name
    "#{given_name} #{family_name}"
  end
end
