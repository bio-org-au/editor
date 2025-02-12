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

#  A tree version element - a link table between tree version and tree element
#  The tree version element tells you which tree elements are in this version
#  of a tree. It has a specific identifier called element_link and a taxon
#  identifier called taxon_link

#  A Tree Version Element is a link between the tree version and the tree element.
# == Schema Information
#
# Table name: tree_version_element
#
#  depth           :integer          not null
#  element_link    :text             not null, primary key
#  merge_conflict  :boolean          default(FALSE), not null
#  name_path       :text             not null
#  taxon_link      :text             not null
#  tree_path       :text             not null
#  updated_by      :string(255)      not null
#  updated_at      :timestamptz      not null
#  parent_id       :text
#  taxon_id        :bigint           not null
#  tree_element_id :bigint           not null
#  tree_version_id :bigint           not null
#
# Indexes
#
#  tree_name_path_index                   (name_path)
#  tree_path_index                        (tree_path)
#  tree_version_element_element_index     (tree_element_id)
#  tree_version_element_link_index        (element_link)
#  tree_version_element_parent_index      (parent_id)
#  tree_version_element_taxon_id_index    (taxon_id)
#  tree_version_element_taxon_link_index  (taxon_link)
#  tree_version_element_version_index     (tree_version_id)
#
# Foreign Keys
#
#  fk_80khvm60q13xwqgpy43twlnoe  (tree_version_id => tree_version.id)
#  fk_8nnhwv8ldi9ppol6tg4uwn4qv  (parent_id => tree_version_element.element_link)
#  fk_ufme7yt6bqyf3uxvuvouowhh   (tree_element_id => tree_element.id)
#
class TreeVersionElement < ActiveRecord::Base
  self.table_name = "tree_version_element"
  self.primary_key = "element_link"
  self.sequence_name = "nsl_global_seq"

  belongs_to :tree_version,
             foreign_key: "tree_version_id",
             class_name: "TreeVersion"

  belongs_to :tree_element,
             foreign_key: "tree_element_id",
             class_name: "Tree::Element"

  belongs_to :parent,
             foreign_key: "parent_id",
             class_name: "TreeVersionElement"

  def count_children
    pattern = "^#{tree_path}/.*"

    TreeVersionElement.find_by_sql(["select count(tve) c
from tree_version_element tve
where tve.tree_version_id = ?
  and tve.tree_path ~ ?", tree_version_id, pattern]).first["c"]
  end

  def tree_ordered_name_ids
    Name.find_by_sql(["
with RECURSIVE walk (name_id, rank, parent_id) as (
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  from tree_version_element tve join tree_element te on tve.tree_element_id = te.id
  where element_link = ?
  UNION ALL
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  from walk, tree_version_element tve join tree_element te on tve.tree_element_id = te.id
  where element_link = walk.parent_id
)
select name_id from walk", element_link])
  end

  def tree_ordered_names
    name_ids = tree_ordered_name_ids
    name_ids.reverse.collect { |nameId| Name.includes(:name_rank).find(nameId.name_id) }
  end

  def comment_key
    tree_version.comment_key
  end

  def comment?
    tree_element.profile_key(comment_key).present?
  end

  def comment
    tree_element.profile_value(comment_key)
  end

  def distribution_key
    tree_version.distribution_key
  end

  def distribution?
    tree_element.profile_key(distribution_key).present?
  end

  def distribution
    tree_element.profile_value(distribution_key)
  end

  def full_element_link
    "#{host_part}#{element_link}"
  end

  def full_taxon_link
    "#{host_part}#{taxon_link}"
  end

  def host_part
    tree_version.host_part
  end

  # returns a record containing identifying information to edit the distribution
  def distribution_record
    record = {}
    record.tree_version_element = self
    record.field_name = tree_element.distribution? ? tree_element.distribution_key : "Distribution"
    record.field_value = if tree_element.distribution?
                           tree_element.distribution_value
                         else
                           "WA, CoI, ChI, AR, CaI, NT, SA, Qld, CSI, NSW, LHI, NI, ACT, Vic, Tas, HI, MDI, MI"
                         end
    record.multiline = false
    record
  end

  def comment_record
    record = new Object
    record.tree_version_element = self
    record.field_name = tree_element.comment? ? tree_element.comment_key : "Comment"
    record.field_value = if tree_element.comment?
                           tree_element.comment_value
                         else
                           ""
                         end
    record.multiline = false
    record
  end
end
