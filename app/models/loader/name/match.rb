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
# Loader Name entity
class Loader::Name::Match < ActiveRecord::Base
  strip_attributes
  self.table_name = "loader_name_match"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  belongs_to :loader_name, class_name: "Loader::Name", foreign_key: "loader_name_id"
  belongs_to :name, class_name: "::Name", foreign_key: "name_id"
  belongs_to :instance
  belongs_to :instance_type, foreign_key: :relationship_instance_type_id, optional: true
  validates :loader_name_id, uniqueness: true,
            unless: Proc.new {|a| a.loader_name.record_type == 'misapplied'}
end

