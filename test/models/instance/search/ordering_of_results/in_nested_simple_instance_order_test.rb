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
require "models/instance/search/ordering_of_results/nested_simple_helper"

# Single instance model test.
class InNestedSimpleInstanceOrderTest < ActiveSupport::TestCase
  def assert_with_args(results, index, expected)
    actual = "#{results[index].page} - #{results[index].name.full_name}"
    assert(/\A#{Regexp.escape(actual)}\z/.match(expected),
           "Wrong at index #{index}; should be: #{expected} NOT #{actual}")
  end

  setup do
    @results = Instance.joins(:instance_type, :reference, :name)
                       .where.not(page: "exclude-from-ordering-test")
                       .in_nested_instance_type_order
                       .order(Arel.sql('reference.iso_publication_date,lower(name.full_name) collate "C"'))
                       .order(Arel.sql("instance_type.name")) # make test order definitive
    @ndx = 0
  end

  test "instances in nested simple instance order" do
    # Very useful debug
    # @results.each_with_index do |i,ndx|
    #   puts "#{ndx}: #{i.page} - #{i.name.full_name}" if ndx < 80
    # end
    test1
    test2
    test3
    test4
    test5
    test6
    test7
    test8
    test9
    test10
  end
end

