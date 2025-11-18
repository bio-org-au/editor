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

#  A tree - usually a classification
# == Schema Information
#
# Table name: tree_join_v
#
#  accepted_tree                 :boolean
#  config                        :jsonb
#  depth                         :integer
#  description_html              :text
#  display_html                  :text
#  draft_name                    :text
#  element_link                  :text
#  excluded                      :boolean
#  group_name                    :text
#  host_name                     :text
#  instance_link                 :text
#  link_to_home_page             :text
#  log_entry                     :text
#  merge_conflict                :boolean
#  name                          :text
#  name_element                  :string(255)
#  name_link                     :text
#  name_path                     :text
#  profile                       :jsonb
#  published                     :boolean
#  published_at                  :timestamptz
#  published_by                  :string(100)
#  rank                          :string(50)
#  simple_name                   :text
#  source_element_link           :text
#  source_shard                  :text
#  synonyms                      :jsonb
#  synonyms_html                 :text
#  taxon_link                    :text
#  tree_element_id_fk            :bigint
#  tree_path                     :text
#  tree_version_id_fk            :bigint
#  current_tree_version_id       :bigint
#  default_draft_tree_version_id :bigint
#  instance_id                   :bigint
#  name_id                       :bigint
#  parent_id                     :text
#  previous_element_id           :bigint
#  previous_version_id           :bigint
#  reference_id                  :bigint
#  taxon_id                      :bigint
#  tree_element_id               :bigint
#  tree_id                       :bigint
#  tree_version_id               :bigint
#
class TreeJoinV < ApplicationRecord
  self.table_name = "tree_join_v"
  scope :draft, -> { where("not published") }
  scope :accepted, -> { where("accepted_tree = true") }
  scope :current, -> { where("tree_version_id = current_tree_version_id") }
  scope :current_accepted, -> { where("tree_version_id = current_tree_version_id and accepted_tree") }
  scope :old, -> { where("tree_version_id != current_tree_version_id") }

  belongs_to :instance
  belongs_to :name

  def readonly?
    true
  end

  def self.name_in_synonymy_query(name_id)
    TreeJoinV.accepted.current
             .where(['instance_id in
                        (select cited_by_id
                           from instance
                          where name_id = ?)', name_id])
             .count
  end

  def self.name_in_synonymy?(name_id)
    name_in_synonymy_query(name_id) > 0
  end

  def self.synonym_in_names_query(name_id)
    TreeJoinV.accepted.current
             .where(['instance_id in
                       (select id
                          from instance
                         where name_id = ?)', name_id])
             .count
  end

  def self.synonym_in_names?(name_id)
    synonym_in_names_query(name_id) > 0
  end

  def sub_taxa_in_draft_accepted_tree
    TreeJoinV.where(accepted_tree: true).where(published: false).where(parent_id: self.element_link)
  end

  def parent_in_draft_accepted_tree
    TreeJoinV.where(accepted_tree: true).where(published: false).find_by(element_link: self.parent_id)
  end

  def has_sub_taxa_in_draft_accepted_tree?
    sub_taxa_in_draft_accepted_tree.size > 0
  end
end
