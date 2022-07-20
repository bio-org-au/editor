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

#  A tree version
class TreeVersion < ActiveRecord::Base
  self.table_name = "tree_version"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :tree, class_name: "Tree"

  has_many :tree_version_elements,
           foreign_key: "tree_version_id",
           class_name: "TreeVersionElement"
  alias_attribute :tves, :tree_version_elements

  # Returns a TreeVersionElement for this TreeVersion which contains the name
  def name_in_version(name)
    tree_version_elements.joins(:tree_element)
        .where(tree_element: {name: name}).first
  end

  # Returns a TreeVersionElement for this TreeVersion which contains the name
  def instance_in_version(instance)
    tree_version_elements.joins(:tree_element)
        .where(tree_element: {instance: instance}).first
  end

  def query_name_in_version(term)
    tree_version_elements
        .joins(:tree_element)
        .where(["lower(tree_element.simple_name) like lower(?)", term])
        .order(:name_path)
        .limit(50)
  end

  def query_name_in_version_at_rank(term, rank_name)
    tree_version_elements
        .joins(:tree_element)
        .where(["lower(tree_element.simple_name) like lower(?) and tree_element.rank = ?", term, rank_name])
        .limit(15)
  end

  def query_name_version_ranks(term, rank_names)
    tree_version_elements
        .joins(:tree_element)
        .where(["lower(tree_element.simple_name) like lower(?) and tree_element.rank in (?)", term, rank_names])
        .order(:name_path)
        .limit(15)
  end

  def last_update
    self.tree_version_elements.order(updated_at: :desc).first
  end

  def user_can_edit?(user)
    user && user.groups.include?(tree.group_name)
  end

  def comment_key
    tree.config["comment_key"]
  end

  def distribution_key
    tree.config["distribution_key"]
  end

  def host_part
    tree.host_name
  end

  def draft_instance_default?
    self != tree.default_draft_version
  end
end
