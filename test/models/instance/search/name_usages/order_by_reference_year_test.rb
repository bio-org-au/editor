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
load "models/search/users.rb"

# Single instance model test.
class NameUsagesOrderByReferenceYear < ActiveSupport::TestCase
  def setup
    @name = names(:casuarina_inophloia)
    # Sorted chronologically: dated instances first, then undated (within same draft group)
    @first_ref = references(:australasian_chemist_and_druggist)  # 1881
    @second_ref = references(:mueller_1882_section)              # 1882
    @third_ref = references(:bailey_catalogue_qld_plants)        # 1913
    @fourth_ref = references(:ref_with_no_year)                  # no year (after dated non-drafts)
    @params = ActiveSupport::HashWithIndifferentAccess.new(
      query_string: "id:#{@name.id} show-instances:",
      query_target: "Name",
      current_user: build_edit_user
    )
  end

  test "instance search name usages for casuarina inophloia order" do
    search = Search::Base.new(@params)
    assert_equal search.executed_query.results.class,
                 Array, "Results should be an Array"
    results = search.executed_query.results
    # print_data(results)
    assert_equal 5, results.size, "5 records expected."
    assert_equal @name.id, results[1].name_id, "Expected a different name."
    assert_equal @first_ref.id,
                 results[1].reference_id,
                 "First reference (1881) wrong: got #{results[1].reference.iso_publication_date}"
    assert_equal @second_ref.id,
                 results[2].reference_id,
                 "Second reference (1882) wrong"
    assert_equal @third_ref.id,
                 results[3].reference_id,
                 "Third reference (1913) wrong"
    assert_equal @fourth_ref.id,
                 results[4].reference_id,
                 "Fourth reference (no year, should be last) wrong"
  end

  def print_data(results)
    results.each do |r|
      if r.instance_of?(Instance)
        puts
        "#{r.reference.citation}; date: #{r.reference.iso_publication_date}"
      end
    end
  end
end
