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

# SessionUser model - not an active record.
class SessionUser < ActiveType::Object
  attr_accessor :username, :full_name, :groups

  validates :username, presence: true
  validates :full_name, presence: true
  validates :groups, presence: true

  #
  # Profile V2
  #
  def profile_v2?
    # NOTE: we may have to change this to a different group
    groups.include?('foa')
  end

  def profile_v2_context
    @profile_v2_context ||= ::Users::ProfileContext.new(self).context
  end

  #
  # Edit
  #
  def edit?
    groups.include?("edit")
  end

  def admin?
    groups.include?("admin")
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

  def foa_context_group?
    groups.include?('foa-context-group')
  end

  def v2_profile_instance_edit?
    groups.include?('v2-profile-instance-edit')
  end
end
