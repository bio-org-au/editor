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

#  Distribution Region
# == Schema Information
#
# Table name: dist_entry
#
#  id           :bigint           not null, primary key
#  display      :string(255)      not null
#  lock_version :bigint           default(0), not null
#  sort_order   :integer          default(0), not null
#  region_id    :bigint           not null
#
# Foreign Keys
#
#  fk_ffleu7615efcrsst8l64wvomw  (region_id => dist_region.id)
#
class DistEntry < ApplicationRecord
  self.table_name = "dist_entry"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :dist_region,
             foreign_key: "region_id"

  has_and_belongs_to_many :dist_statuses,
                          join_table: "dist_entry_dist_status",
                          foreign_key: "dist_entry_status_id"

  has_and_belongs_to_many :tree_elements,
                          join_table: "tree_element_distribution_entries",
                          foreign_key: "dist_entry_id"

  def region
    dist_region.name
  end

  def entry
    :display
  end

  def self.id_for_display(display)
    DistEntry.find_by(display: display).id
  end
end
