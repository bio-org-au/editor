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
# Table name: name_tag_name
#
#  created_by :string(255)      not null
#  updated_by :string(255)      not null
#  created_at :timestamptz      not null
#  updated_at :timestamptz      not null
#  name_id    :bigint           not null, primary key
#  tag_id     :bigint           not null, primary key
#
# Indexes
#
#  name_tag_name_index  (name_id)
#  name_tag_tag_index   (tag_id)
#
# Foreign Keys
#
#  fk_22wdc2pxaskytkgpdgpyok07n  (name_id => name.id)
#  fk_2uiijd73snf6lh5s6a82yjfin  (tag_id => name_tag.id)
#
class NameTagName < ApplicationRecord
  self.table_name = "name_tag_name"
  self.primary_key = [:name_id, :tag_id]

  belongs_to :name
  belongs_to :name_tag, foreign_key: :tag_id
  validates :name_id, presence: true
  validates :tag_id, presence: true
  validates :tag_id, uniqueness: { scope: :name_id, message: "is already attached." }
  validates :created_by, presence: true
  validates :updated_by, presence: true

  def save_new_record_with_username(username)
    self.created_by = self.updated_by = username
    save!
  end
end
