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

# User model.
class User < ActiveType::Object
  attr_accessor :username, :full_name, :groups

  validates :username, presence: true
  validates :full_name, presence: true
  validates :groups, presence: true

  def edit?
    groups.include?("edit")
  end

  def admin?
    groups.include?("admin")
  end

  # TODO: remove this - NSL-2007
  def apc?
    groups.include?("APC")
  end

  def qa?
    groups.include?("QA")
  end

  def treebuilder?
    groups.include?("treebuilder")
  end

  def reviewer?
    groups.include?("taxonomic-review")
  end

  def compiler?
    groups.include?("treebuilder")
  end

  def batch_loader?
    groups.include?("batch-loader")
  end

  def loader_2_tab_loader?
    groups.include?("loader-2-tab")
  end
end
