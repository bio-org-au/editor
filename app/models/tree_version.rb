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
# == Schema Information
#
# Table name: tree_version
#
#  id                  :bigint           not null, primary key
#  created_by          :string(255)      not null
#  draft_name          :text             not null
#  lock_version        :bigint           default(0), not null
#  log_entry           :text
#  published           :boolean          default(FALSE), not null
#  published_at        :timestamptz
#  published_by        :string(100)
#  created_at          :timestamptz      not null
#  previous_version_id :bigint
#  tree_id             :bigint           not null
#
# Foreign Keys
#
#  fk_4q3huja5dv8t9xyvt5rg83a35  (tree_id => tree.id)
#  fk_tiniptsqbb5fgygt1idm1isfy  (previous_version_id => tree_version.id)
#
class TreeVersion < ActiveRecord::Base
  self.table_name = "tree_version"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :tree, class_name: "Tree"

  has_many :tree_version_elements,
           foreign_key: "tree_version_id",
           class_name: "TreeVersionElement"

  before_save :stop_if_read_only

  # Returns a TreeVersionElement for this TreeVersion which contains the name
  def name_in_version(name)
    tree_version_elements.joins(:tree_element)
                         .where(tree_element: { name: name }).first
  end

  # Returns a TreeVersionElement for this TreeVersion which contains the name
  def instance_in_version(instance)
    tree_version_elements.joins(:tree_element)
                         .where(tree_element: { instance: instance }).first
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
    tree_version_elements.order(updated_at: :desc).first
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

  def stop_if_read_only
    if tree.read_only?
      errors.add(:base, ' parent tree is read only')
      throw :abort
    end
  end
end
