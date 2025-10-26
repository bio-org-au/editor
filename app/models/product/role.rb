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
# Table name: product_role
#
#  id           :bigint           not null, primary key
#  created_by   :string(50)       not null
#  deprecated   :boolean          default(FALSE), not null
#  lock_version :bigint           default(0), not null
#  updated_by   :string(50)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#  product_id   :bigint           not null
#  role_id      :bigint           not null
#
# Indexes
#
#  pr_unique_product_role  (product_id,role_id) UNIQUE
#
# Foreign Keys
#
#  pr_product_fk  (product_id => product.id)
#  pr_role_fk     (role_id => roles.id)
#
class Product::Role < ActiveRecord::Base
  strip_attributes
  self.table_name = "product_role"
  self.primary_key = "id"
  belongs_to :role, class_name: "::Role"
  belongs_to :product
  has_many :user_product_roles, class_name: "User::ProductRole", foreign_key: :product_role_id
  has_many :user_product_role_vs

  def name
    "#{product.name} #{role.name} product role"
  end
end
