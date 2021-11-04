# frozen_string_literal: true

require 'open-uri'

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

#  A tree element - holds the taxon information
class TreeElement < ActiveRecord::Base
  self.table_name = "tree_element"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :instance, class_name: "Instance"

  belongs_to :name, class_name: "Name"

  has_many :tree_version_elements,
           foreign_key: "tree_element_id"

  has_and_belongs_to_many :dist_entries,
                          class_name: "DistEntry",
                          join_table: "tree_element_distribution_entries",
                          foreign_key: "tree_element_id"

  def self.dist_options
    DistEntry.all.sort do |a, b|
      a.sort_order <=> b.sort_order
    end.collect(&:display)
  end

  def distribution_value
    profile[distribution_key]["value"]
  end

  def distribution?
    distribution_key.present?
  end

  def distribution_key
    profile_key(/Dist/)
  end

  def dist_options_disabled
    disabled_options = []
    all = DistEntry.all
    for n in dist_entries.collect(&:region)
      disabled_options.concat(all.find_all {|opt| opt.dist_region.name == n}.collect(&:display))
    end
    disabled_options
  end

  def current_dist_options
    dist_entries.collect(&:display)
  end

  def construct_distribution_string
    dist_entries
        .sort {|a, b| a.dist_region.sort_order <=> b.dist_region.sort_order}
        .collect(&:entry)
        .join(', ')
  end

  def comment?
    comment_key.present?
  end

  def comment_key
    profile_key(/Comment/)
  end

  def comment_value
    profile[comment_key]["value"]
  end

  def profile_value(key_string)
    key = profile_key(key_string)
    if key
      profile[key]["value"]
    else
      ""
    end
  end

  def profile_key(key_string)
    profile.keys.find {|key| key_string == key} if profile.present?
  end
end
