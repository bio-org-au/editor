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

# Single name model test.
class NotIfHasDuplicatesTest < ActiveSupport::TestCase
  test "do not allow delete if name has duplicates" do
    name = names(:deletable_apart_from_duplicate)
    assert name.duplicates.size.positive?, "Test name should have a duplicate"
    assert_not name.allow_delete?, "should not allow delete because duplicates"
    name.duplicates.each do |duplicate|
      duplicate.duplicate_of_id = nil
      duplicate.save
    end
    changed_name = Name.find(name.id)
    assert changed_name.duplicates.empty?, "Now should not have duplicates"
    assert changed_name.allow_delete?, "Should allow delete now"
  end
end
