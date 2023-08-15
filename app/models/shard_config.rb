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

#   Shard Config model
class ShardConfig < ActiveRecord::Base
  self.table_name = "shard_config"
  NAME_SPACE = "name space"

  def self.name_space
    @name_space ||= ShardConfig.find_by(name: NAME_SPACE).value
  end

  def self.classification_tree_key
    ShardConfig.find_by(name: "classification tree key").value
  end

  # On by default
  def self.name_parent_rank_restriction
    results = ShardConfig.where(name: "name parent rank restriction")
    return true if results.blank?
    return true if results.first.value == "on"

    false
  end

  def self.name_parent_rank_restriction?
    name_parent_rank_restriction
  end

  def self.shard_group_name
    ShardConfig.find_by(name: "shard group name").try("value") || "NSL"
  end
end
