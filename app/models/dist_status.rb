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
# Table name: dist_status
#
#  id               :bigint           not null, primary key
#  def_link         :string(255)
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  sort_order       :integer          default(0), not null
#
class DistStatus < ActiveRecord::Base
  self.table_name = "dist_status"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  has_and_belongs_to_many :dist_entries,
                          join_table: "dist_entry_dist_status",
                          foreign_key: "dist_status_id"

  has_and_belongs_to_many :dist_statuses,
                          join_table: "dist_status_dist_status",
                          foreign_key: "dist_status_id",
                          association_foreign_key: "dist_status_combining_status_id"

  def self.status_names
    DistStatus.all
              .sort { |a, b| a.sort_order <=> b.sort_order }
              .collect { |ds| ds.name }
  end
end
