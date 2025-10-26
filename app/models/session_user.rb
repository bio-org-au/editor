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

  attr_reader :product_from_context

  validates :username, presence: true
  validates :full_name, presence: true
  validates :groups, presence: true

  def set_current_product_from_context(product)
    @product_from_context = product
  end

  def with_role?(requested_role_name)
    return unless user

    user.is?(requested_role_name)
  end

  #
  # Profile V2
  #
  def product_from_roles
    user&.available_product_from_roles
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

  # find_or_create_by would be preferred method but
  # I couldn't get that to work
  def registered_user
    registered_user = User.find_or_initialize_by(user_name: username.downcase) do |user|
      user.family_name = full_name.split(' ').last||'unknown'
      user.given_name = full_name.split(' ').first||'unknown'
    end

    registered_user.save if registered_user.new_record?
    registered_user
  end

  def user
    @user ||= User.find_by(user_name: username)
  end

  def user_name
    @username
  end

  def user_id
    @user.id
  end

  def inspect
    {
      username: @username,
      full_name: @full_name,
      groups: @groups,
      user: @user.inspect
    }
  end
end
