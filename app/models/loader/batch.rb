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
# Loader Batch entity
class Loader::Batch < ActiveRecord::Base
  strip_attributes
  self.table_name = "loader_batch"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  has_many :loader_names, class_name: "Loader::Name", foreign_key: "loader_batch_id"
  has_many :batch_reviews, class_name: "Loader::Batch::Review", foreign_key: "loader_batch_id"

  attr_accessor :give_me_focus, :message

  # before_create :set_defaults # rails 6 this was not being called before the validations
  before_save :compress_whitespace

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    'Loader Batch'
  end
end

