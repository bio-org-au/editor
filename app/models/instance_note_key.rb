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
class InstanceNoteKey < ActiveRecord::Base
  self.table_name = "instance_note_key"
  self.primary_key = "id"
  APC_DIST = "APC Dist."
  NOTE_MATCHES = "-note-matches:"
  has_many :instance_notes
  scope :apc, -> { where(name: ["APC Comment", "APC Dist."]) }
  scope :apc_comment, -> { where(name: ["APC Comment"]) }
  scope :apc_dist, -> { where(name: [APC_DIST]) }
  scope :non_apc, -> { where.not(name: ["APC Comment", "APC Dist."]) }

  def self.edit_options
    all.order(:sort_order)
       .collect do |key|
      [decorated_dep(key),
       key.id,
       { disabled: key.deprecated? }]
    end
  end

  def self.decorated_dep(key)
    if key.deprecated
      "#{key.name} (deprecated)"
    else
      key.name
    end
  end

  def self.apc_options
    all.where(deprecated: false)
       .apc
       .order(:sort_order)
       .collect { |n| [n.name, n.id] }
  end

  def self.apc_options_for_instance(instance)
    if instance.apc_dist_note?
      all.where(deprecated: false)
         .apc_comment
         .order(:sort_order)
         .collect { |n| [n.name, n.id] }
    else
      apc_options
    end
  end

  def self.non_apc_options
    all.where(deprecated: false)
       .non_apc.order(:sort_order)
       .collect { |n| [n.name, n.id] }
  end

  def self.query_form_options
    all.where(deprecated: false)
       .sort_by(&:name)
       .collect { |n| [n.name, n.name.downcase, { class: "" }] }
  end

  def apc_dist?
    name == APC_DIST
  end

  def self.string_has_embedded_note_key?(str)
    if str.match(/#{NOTE_MATCHES}\z/i)
      possible_key = str.sub(/#{NOTE_MATCHES}\z/i, "").gsub("-", " ")
      where(["lower(name) = lower(?)", possible_key]).size == 1
    else
      false
    end
  end
end
