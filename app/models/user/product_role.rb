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
#  created_by           :string(50)       not null
#  lock_version         :bigint           default(0), not null
#  updated_by           :string(50)       not null
#  created_at           :timestamptz      not null
#  updated_at           :timestamptz      not null
#  product_id           :bigint           not null, primary key
#  product_role_type_id :bigint           not null, primary key
#  user_id              :bigint           not null, primary key
#
# Foreign Keys
#
#  upr_product_fk            (product_id => product.id)
#  upr_product_role_type_fk  (product_role_type_id => product_role_type.id)
#  upr_users_fk              (user_id => users.id)
#
class User::ProductRole < ActiveRecord::Base
  strip_attributes
  self.table_name = "user_product_role"
  self.primary_key = %i[user_id product_id product_role_type_id]
  belongs_to :user
  belongs_to :product
  belongs_to :role_type, class_name: "Product::RoleType", foreign_key: "product_role_type_id"
end
