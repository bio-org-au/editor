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
require "models/name/as_typeahead/name_parent/name_parent_test_helper"

# Single Name typeahead test.
class ForSuperspeciesFullyRestrictedTest < ActiveSupport::TestCase
  def setup
    set_name_parent_rank_restrictions_on
  end

  test "name parent suggestion for superspecies" do
    typeahead = Name::AsTypeahead::ForParent.new(
      term: "%",
      avoid_id: 1,
      rank_id: NameRank.find_by(name: "Superspecies").id
    )
    suggestions_should_only_include(
      typeahead.suggestions,
      "Superspecies",
      %w[Subseries Series Subsectio Sectio Subgenus Genus]
    )
  end
end
