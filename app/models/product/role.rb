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
# Foreign Keys
#
#  upr_product_fk            (product_id => product.id)
#  upr_role_fk               (role_id => role.id)
#
class Product::Role < ActiveRecord::Base
  strip_attributes
  self.table_name = "product_role"
  self.primary_key = "id"
  belongs_to :role, class_name: "::Role"
  belongs_to :product
  has_many :user_product_role, class_name: "User::ProductRole"
end
