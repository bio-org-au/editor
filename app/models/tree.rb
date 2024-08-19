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
class Tree < ActiveRecord::Base
  self.table_name = "tree"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :default_draft_version,
             class_name: "TreeVersion",
             foreign_key: "default_draft_tree_version_id"

  belongs_to :current_tree_version,
             class_name: "TreeVersion",
             foreign_key: "current_tree_version_id"

  has_many :tree_versions,
           foreign_key: "tree_id"

  scope :accepted,
        (lambda do
          where(name: ShardConfig.classification_tree_key)
        end)

  def self.menu_drafts
    Tree.joins("LEFT OUTER JOIN tree_version draft_version on draft_version.tree_id = tree.id")
        .where("draft_version.published = false")
        .select("tree.id, name, draft_version.id as draft_id, draft_version.draft_name, draft_version.log_entry")
        .order("tree.name")
  end

  def config?
    config.present?
  end

  def comment_key
    config["comment_key"]
  end

  def distribution_key
    config["distribution_key"]
  end
end
