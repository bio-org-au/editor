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

# Single Name typeahead test.
class ShouldIncludeATwoInstancesCount < ActiveSupport::TestCase
  test "name parent suggestions should include a two instances count" do
    dummy_avoid_id = 1
    name = Name.find_by(full_name: "a genus with two instances")
    assert name.present?,
           "The name 'a genus with two instances' should be found."
    assert name.instances.size == 2,
           "The name 'a genus with two instances' should have two instances."
    typeahead =
      Name::AsTypeahead::ForParent.new(term: "a genus with two instances",
                                       avoid_id: dummy_avoid_id,
                                       rank_id: NameRank.species.id)
    assert(typeahead.suggestions.is_a?(Array), "suggestions should be an array")
    assert(typeahead.suggestions.size == 1,
           'suggestions for "a genus with two instances" should have a record')
    assert_match(
      "a genus with two instances | Genus | 2 instances",
      typeahead.suggestions.first[:value],
      "Name parent typeahead needs correct value with a 2 instances count"
    )
  end
end
