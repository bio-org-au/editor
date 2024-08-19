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
class NameTagName < ActiveRecord::Base
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
