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
class NameSuggestionsParentOrderingForSpeciesTest < ActiveSupport::TestCase
  test "name parent suggestion ordering for species" do
    @typeahead = Name::AsTypeahead::ForParent.new(
      term: "%",
      avoid_id: 1,
      rank_id: NameRank.species.id
    )
    check_order
  end

  # Checking order of suggestions that look like this:
  #
  # a duplicate genus not | Genus | legitimate | 0 instances
  # a genus with one instance | Genus | legitimate | 1 instance
  # a genus with two instances | Genus | legitimate | 2 instances
  # a_sectio | Sectio | legitimate | 1 instance
  # a_series | Series | legitimate | 1 instance
  # a_subgenus | Subgenus | legitimate | 1 instance
  def check_order
    @first = true
    @previous_rank_sort_order = 1_000_000
    @previous_rank = NameRank.first
    @typeahead.suggestions.each do |suggestion|
      check_position(suggestion)
    end
  end

  def check_position(suggestion)
    rank = rank_from_suggestion(suggestion)
    if @first
      @first = false
    else
      assert rank.sort_order >= @previous_rank_sort_order,
             %(Rank "#{rank.name}" is higher than previously ) \
             "listed rank '#{@previous_rank.name}'"
    end
    @previous_rank_sort_order = rank.sort_order
    @previous_rank = rank
  end
end
