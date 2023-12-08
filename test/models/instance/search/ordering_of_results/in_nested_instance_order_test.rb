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

# Single instance model test.
class InNestedInstanceOrderTest < ActiveSupport::TestCase
  INSTANCE_TYPE_NAMES = ["basionym",
                         "common name",
                         "vernacular name",
                         "doubtful nomenclatural synonym",
                         "nomenclatural synonym",
                         "doubtful taxonomic synonym",
                         "taxonomic synonym",
                         "doubtful pro parte nomenclatural synonym",
                         "pro parte nomenclatural synonym",
                         "pro parte taxonomic synonym",
                         "doubtful pro parte taxonomic synonym"].freeze

  def assert_with_args(results, index, expected)
    assert(
      /\A#{Regexp.escape(expected)}\z/.match(results[index].instance_type.name),
      "Wrong at index #{index}; should be: #{expected}
      NOT #{results[index].instance_type.name}"
    )
  end

  # TODO: revise after ordering code changes
  test "instances in synonymy order" do
    run_query
    test1
    # test2
  end

  # This emulates synonymy ordering in the Editor, note especially the scope in_synonymy_order.
  def run_query
    @results = Instance.joins(:instance_type, :name, :reference)
                       .joins("inner join name_status ns on name.name_status_id = ns.id")
                       .joins("inner join instance cites on instance.cites_id = cites.id")
                       .joins("inner join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
                       .in_synonymy_order
    # extra order clause to make definitive and
    # repeatable ordering for these tests
    #
    # Debug
    # @results.each_with_index do |i,ndx|
     # puts "#{ndx}: #{i.instance_type.name}: #{i.name.simple_name} - #{i.instance_type.taxonomic ? 'taxonomic' : 'not taxonomic'}" if ndx < 30
    # end
  end

  #  Expected set (but not expected order)
  #  0: basionym: Metrosideros costata Gaertn. - not taxonomic
  #  1: basionym: name in secondary ref - not taxonomic
  #  2: common name: nothing - not taxonomic
  #  3: common name: Rusty Gum - not taxonomic
  #  4: doubtful nomenclatural synonym: name one for eflora - not taxonomic
  #  5: doubtful pro parte taxonomic synonym: name one for eflora - taxonomic
  #  6: doubtful taxonomic synonym: name one for eflora - taxonomic
  #  7: nomenclatural synonym: Metrosideros costata Gaertn. - not taxonomic
  #  8: nomenclatural synonym: Metrosideros costata - not taxonomic
  #  9: pro parte nomenclatural synonym: name one for eflora - not taxonomic
  #  10: taxonomic synonym: Angophora lanceolata - taxonomic
  #  11: vernacular name: Rusty Gum - not taxonomic

  def test1
    assert_with_args(@results, 0, "basionym")
    assert_with_args(@results, 1, "nomenclatural synonym")
    assert_with_args(@results, 2, "nomenclatural synonym")
    assert_with_args(@results, 3, "nomenclatural synonym")
    assert_with_args(@results, 4, "taxonomic synonym")
    # assert_with_args(@results, 2, "doubtful nomenclatural synonym")
    # assert_with_args(@results, 3, "doubtful pro parte taxonomic synonym")
    # assert_with_args(@results, 4, "doubtful taxonomic synonym")
    # assert_with_args(@results, 5, "nomenclatural synonym")
  end

  def test2
    assert_with_args(@results, 6, "nomenclatural synonym")
    assert_with_args(@results, 7, "pro parte nomenclatural synonym")
    assert_with_args(@results, 8, "taxonomic synonym")
    assert_with_args(@results, 9, "common name")
    assert_with_args(@results, 10, "common name")
    assert_with_args(@results, 11, "vernacular name")
  end
end
