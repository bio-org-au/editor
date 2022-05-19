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
  belongs_to :standalone_instance, class_name: "::Instance",
    foreign_key: "standalone_instance_id", optional: true
  validates :loader_name_id, uniqueness: true,
            unless: Proc.new {|a| a.loader_name.record_type == 'misapplied'}
  validates :standalone_instance_id, absence: true, if: :using_default_ref?
  validates :standalone_instance_found, exclusion: {in: [true], message: 'not found'}, if: :using_default_ref?

  def using_default_ref?
    use_batch_default_reference == true
  end

  validates :use_batch_default_reference, exclusion: {in: [true], message:'not both'}, if: :standalone?

  def standalone?
    !standalone_instance_id.blank? && !copy_synonyms_and_append_extras
  end

  def copy_and_append?
    !standalone_instance_id.blank? && copy_synonyms_and_append_extras
  end

  def current_taxonomy_instance_choice
    case
      when use_batch_default_reference then
       'Use batch default reference'
      when copy_synonyms_and_append_extras then
       'Copy and append'
      when standalone_instance_id.present? then
       'Use an existing instance'
      else
       'No choice made'
    end
  end

  def taxonomy_choice_made?
    use_batch_default_reference ||
    standalone_instance_id.present?
  end

  def show_default_reference?
    use_batch_default_reference || copy_synonyms_and_append_extras
  end
end

