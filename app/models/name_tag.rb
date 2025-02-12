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
# Table name: name_tag
#
#  id           :bigint           not null, primary key
#  lock_version :bigint           default(0), not null
#  name         :string(255)      not null
#
# Indexes
#
#  uk_o4su6hi7vh0yqs4c1dw0fsf1e  (name) UNIQUE
#
class NameTag < ActiveRecord::Base
  self.table_name = "name_tag"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  validates :version, presence: true
  has_many :name_tag_names, foreign_key: :tag_id
  has_many :names, through: :name_tag_names
end
