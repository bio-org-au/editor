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
class Tree::Element::DistributionEntry < ActiveRecord::Base
  strip_attributes
  self.table_name = "tree_element_distribution_entries"

  belongs_to :dist_entry, class_name: 'DistEntry'
  belongs_to :tree_element, class_name: 'Tree::Element'

  def self.for_tree_element(tree_element_id)
    self.where(tree_element_id: tree_element_id). each do |tede|
      puts 'tede.display'
    end
  end

  def show
    "#{tree_element_id} #{dist_entry.display}"
  end
end

