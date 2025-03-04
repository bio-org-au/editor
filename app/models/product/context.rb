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
# == Schema Information
#
# Table name: product_context(The sets of products that a user can validly set a context for in the editor)
#
#  id(The identifier for a product context record.)                                                                                                                                                              :bigint           not null, primary key
#  api_date(The date when a system user, script, jira or services task last changed this record.)                                                                                                                :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.)                                                                                                            :string(50)
#  created_by(The user id of the person who created this data)                                                                                                                                                   :string(50)       not null
#  description(A description for this context)                                                                                                                                                                   :text             default("Please describe this product context"), not null
#  lock_version(A system field to manage row level locking.)                                                                                                                                                     :bigint           default(0), not null
#  updated_by(The user id of the person who last updated this data)                                                                                                                                              :string(50)       not null
#  created_at(The date and time this data was created.)                                                                                                                                                          :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                                                                                                                                          :timestamptz      not null
#  context_id(A number that represents an available context. Only the name index and default accepted tree can share a context in each dataset ie. in vascular plants - APNI and APC can be in the same context) :bigint           not null
#  product_id(The product for a context)                                                                                                                                                                         :bigint           not null
#
# Indexes
#
#  pc_u_product_context  (context_id,product_id) UNIQUE
#
# Foreign Keys
#
#  pc_product_fk  (product_id => product.id)
#
# For a product, the context in which it is used.
class Product::Context < ApplicationRecord
  self.table_name = "product_context"
  self.primary_key = "id"

  belongs_to :product, foreign_key: "product_id"

  validates :context_id, :created_by, :updated_by, presence: true
end
