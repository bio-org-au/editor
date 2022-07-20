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

# Single author model test.
class MasterHasAbbrevDuplicateNoAbbrevTest < ActiveSupport::TestCase
  test "master has abbrev duplicate has no abbrev" do
    master = authors(:master_with_abbrev)
    dupe = authors(:duplicate_without_abbrev)
    assert dupe.valid?, "Duplicate should be valid"
    assert dupe.abbrev.blank?, "Duplicate should not have an abbreviation."
    dupe.duplicate_of_id = master.id
    assert dupe.valid?,
           "Dupe without abbrev should be valid even if master has abbrev"
  end
end
