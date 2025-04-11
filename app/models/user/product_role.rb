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
# == Schema Information
#
# Table name: user_product_role
#
#  created_by      :string(50)       not null
#  lock_version    :bigint           default(0), not null
#  updated_by      :string(50)       not null
#  created_at      :timestamptz      not null
#  updated_at      :timestamptz      not null
#  product_role_id :bigint           not null
#  user_id         :bigint           not null, primary key
#
# Foreign Keys
#
#  upr_product_role_fk  (product_role_id => product_role.id)
#  upr_users_fk         (user_id => users.id)
#
class User::ProductRole < ActiveRecord::Base
  strip_attributes
  self.table_name = "user_product_role"
  self.primary_key = %i[user_id product_role_id]
  validates :user_id, :product_role_id, presence: true
  validates :user_id, uniqueness: { scope: [:product_role_id],
    message: "already has that product role" }
  belongs_to :user
  belongs_to :product_role, class_name: "Product::Role"
  has_one :product, through: :product_role
  has_one :role, through: :product_role

  def self.create(params, username)
    upr = User::ProductRole.new(params)
    raise upr.errors.full_messages.first.to_s unless upr.save_with_username(username)

    upr
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def display_text
    "#{product.name} #{role.name} role for #{user.user_name}"
  end
end
