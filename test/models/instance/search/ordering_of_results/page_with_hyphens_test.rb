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

# Instance model test for default and non-default ordering.
class InstanceSearchOrderOfResultsPageWithHyphensTest < ActiveSupport::TestCase
  setup do
    @reference = references(:reference_1_for_instance_ordering_by_page)
    @with_hyphen = instances(:page_57_hyphen_58)
    @without_hyphen = instances(:page_57)
  end

  # Precondition test to confirm the default is not correct for page order,
  # otherwise, the second test might succeed due to name order.
  test "instance search ordering of results by name" do
    results = Instance
              .joins(:reference) \
              .joins(:name) \
              .where(reference_id: @reference.id) \
              .ordered_by_name
    # print_results(results)
    assert results.first.id == @with_hyphen.id,
           "Wrong name order at first value: #{results[0].id}."
    assert results.second.id == @without_hyphen.id,
           "Wrong name order at second value: #{results[1].id}."
  end

  # This is the important test.
  test "instance search ordering of results by page" do
    results = Instance
              .joins(:reference) \
              .joins(:name) \
              .where(reference_id: @reference.id) \
              .ordered_by_page
    # print_results(results)
    assert results.first.id == @without_hyphen.id,
           "Wrong page order at first value: #{results[0].id}."
    assert results.second.id == @with_hyphen.id,
           "Wrong page order at second value: #{results[1].id}."
  end

  def print_results(results)
    results.each_with_index do |i, ndx|
      puts "#{ndx}: #{i.page} - #{i.name.full_name}" if ndx < 30
    end
  end
end
