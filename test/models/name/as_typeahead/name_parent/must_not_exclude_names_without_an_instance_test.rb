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
class MustNotExcludeNamesWithoutAnInstanceTest < ActiveSupport::TestCase
  def set_up
    restriction = ShardConfig.find_by(name: "name parent rank restriction")
    restriction.value = "off"
    restriction.save!
  end

  test "name parent suggestions should not exclude names without an instance" do
    name = Name.find_by(full_name: "a genus without an instance")
    assert name.present?,
           'The name "a genus without an instance" should be found.'
    assert name.instances.empty?,
           "The name 'a genus without an instance' should have no instances."
    typeahead = Name::AsTypeahead::ForParent.new(
      term: "a genus without an instance",
      avoid_id: 1,
      rank_id: NameRank.species.id
    )
    assert(typeahead.suggestions.is_a?(Array),
           "suggestions should be an array")
    assert(typeahead.suggestions.size == 1,
           'suggestions for "a genus without an instance" should have a record')
  end
end
