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
require "test_helper"

# Single model test.
class TreeMenuDraftsTest < ActiveSupport::TestCase

  test "tree menu drafts list is correct" do
    confirm_ron_read_only
    with_ron_read_only
    make_ron_not_read_only
    with_ron_not_read_only
    make_ron_read_only
  end

  def confirm_ron_read_only
    ron = Tree.find_by(name: 'RON')
    assert ron.read_only?, "RON should start read only..."
  end

  def with_ron_read_only
    assert Tree.find_by(name: 'RON').is_read_only?, "RON should be only"
    menu_drafts = Tree.menu_drafts
    assert_equal 1, menu_drafts.size, "Expecting only one menu draft"
    assert menu_drafts.pluck(:name).include?('APC'), "APC should be in menu drafts"
  end

  def make_ron_not_read_only
    ron = Tree.find_by(name: 'RON')
    ron.is_read_only = false
    ron.save!
  end

  def with_ron_not_read_only
    menu_drafts = Tree.menu_drafts
    assert_equal 2, menu_drafts.size, "Expecting two menu drafts"
    assert menu_drafts.pluck(:name).sort == ['APC','RON'], 'should match'
  end

  def make_ron_read_only
    ron = Tree.find_by(name: 'RON')
    ron.is_read_only = true
    ron.save!
    assert ron.read_only?, "RON should be read only..."
  end
end
