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
# Table name: tree_element
#
#  id                  :bigint           not null, primary key
#  display_html        :text             not null
#  excluded            :boolean          default(FALSE), not null
#  instance_link       :text             not null
#  lock_version        :bigint           default(0), not null
#  name_element        :string(255)      not null
#  name_link           :text             not null
#  profile             :jsonb
#  rank                :string(50)       not null
#  simple_name         :text             not null
#  source_element_link :text
#  source_shard        :text             not null
#  synonyms            :jsonb
#  synonyms_html       :text             not null
#  updated_by          :string(255)      not null
#  updated_at          :timestamptz      not null
#  instance_id         :bigint           not null
#  name_id             :bigint           not null
#  previous_element_id :bigint
#
# Indexes
#
#  tree_element_instance_index  (instance_id)
#  tree_element_name_index      (name_id)
#  tree_element_previous_index  (previous_element_id)
#  tree_simple_name_index       (simple_name)
#  tree_synonyms_index          (synonyms) USING gin
#
# Foreign Keys
#
#  fk_5sv181ivf7oybb6hud16ptmo5  (previous_element_id => tree_element.id)
#
require "open-uri"

#  A tree element - holds the taxon information
class Tree::Element < ActiveRecord::Base
  include Tree::Element::Profile
  include Tree::Element::Profile::Distribution
  include Tree::Element::Profile::Distribution::Validations
  include Tree::Element::Profile::Distribution::UpdateAccepted
  include Tree::Element::Profile::Distribution::LowLevelOps
  include Tree::Element::Profile::Distribution::Tedes
  include Tree::Element::Profile::Comment
  self.table_name = "tree_element"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :instance, class_name: "Instance"

  belongs_to :name, class_name: "Name"

  has_many :tree_version_elements,
           foreign_key: "tree_element_id"

  has_and_belongs_to_many :tede_dist_entries,
                          class_name: "DistEntry",
                          join_table: "tree_element_distribution_entries",
                          foreign_key: "tree_element_id"

  def deprecated_utc_offset_s
    seconds_offset = Time.now.in_time_zone("Australia/Canberra").utc_offset
    hours_offset = seconds_offset / 3600
    mins_offset = seconds_offset % 3600
    hours_offset_s = hours_offset.to_s.rjust(2, "0")
    mins_offset_s = mins_offset.to_s.rjust(2, "0")
    utc_offset = "#{hours_offset_s}:#{mins_offset_s}"
  end
end
