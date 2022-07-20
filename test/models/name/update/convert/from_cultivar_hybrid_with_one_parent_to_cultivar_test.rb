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

# Single Name model test.
class FromCultivarHybridWithOneParentToCultivarTest < ActiveSupport::TestCase
  test "convert name from cultivar hybrid with one parent - to - cultivar" do
    skip
  end

  def skipped
    name = names(:cultivar_hybrid_with_one_parent)
    assert_equal name.raw_category, Name::CULTIVAR_HYBRID_CATEGORY
    # NOTE: cultivar hybrids with one parent were possibly entered
    # incorrectly in the old APNI.
    assert name.second_parent_id.blank?,
           "Expecting 2nd parent to be blank in this fixture."
    assert_not name.valid?,
               "Cultivar Hybrid name with one parent should not be valid"

    name.change_category_to = Name::CULTIVAR_CATEGORY
    assert_equal name.category,
                 Name::CULTIVAR_CATEGORY,
                 "Name category should now be CULTIVAR."

    assert_not name.valid?,
               "Name should still not be valid now as a cultivar name"

    assert name.errors.size == 1, "There should be just 1 error."
    assert name.errors.collect { |k, _v| k.to_s }.include?("name_type_id"),
           "There should be an error for name_type_id."

    name.name_type_id = NameType.find_by(name: "cultivar").id

    assert name.valid?, "Name should be valid now as a cultivar name"
    name.save!
    assert name.raw_category == Name::CULTIVAR_CATEGORY,
           "Name converted from cultivar hybrid should now be a cultivar name"
  end
end
