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
# This model is for the users table created during work on the batch loader and batch review subsystem.
# == Schema Information
#
# Table name: users
#
#  id           :bigint           not null, primary key
#  created_by   :string(50)       not null
#  family_name  :string(60)       not null
#  given_name   :string(60)
#  lock_version :bigint           default(0), not null
#  updated_by   :string(50)       not null
#  user_name    :string(30)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#
# Indexes
#
#  users_name_key  (user_name) UNIQUE
#
class User < ActiveRecord::Base
  strip_attributes
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  has_many :batch_reviewers, class_name: "Loader::Batch::Reviewer", foreign_key: :user_id
  has_many :product_roles, class_name: "User::ProductRole", foreign_key: :user_id
  has_many :products, through: :product_roles

  before_create :set_audit_fields
  before_update :set_updated_by

  def is?(requested_role_type_name)
    product_roles.joins(:role_type).select("product_role_type.name").pluck(:name).include?(requested_role_type_name)
  end

  def available_product_from_roles
    role = "draft-profile-editor" if self.is?("draft-profile-editor")
    role ||= "draft-editor" if self.is?("draft-editor")

    if role
      self.product_roles
        .joins(:role_type)
        .find_by(product_role_type: {name: role})
        .product
    end
  end

  def set_audit_fields
    self.created_by = self.updated_by = @current_user&.username||'unknown'
  end

  def set_updated_by
    self.updated_by = @current_user&.username||'unknown'
  end


  # Note, the PK for the users table is the id column.
  # That appears as user_id as a foreign key.
  # The user's login id is in the column called user_name - called that to avoid
  # confusion with the FK user_id or with the PK id.
  def userid
    user_name
  end

  def self.create(params, username)
    user = User.new(params)
    raise user.errors.full_messages.first.to_s unless user.save_with_username(username)

    user
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
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
    self.user_name = params[:user_name]
    self.given_name = params[:given_name]
    self.family_name = params[:family_name]
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

  def self.users_not_already_reviewers(batch_review)
    self.all.order(:user_name) - batch_review.batch_reviewers.collect {|reviewer| reviewer.user}
  end

  def can_be_deleted?
    batch_reviewers.size.zero?
  end
end
