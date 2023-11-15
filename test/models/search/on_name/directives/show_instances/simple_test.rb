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
load "test/models/search/users.rb"
load "test/models/search/on_name/test_helper.rb"

# Single instance model test.
class SimpleTest < ActiveSupport::TestCase
  def assert_with_args(_results, index, expected, actual)
    assert(/\A#{Regexp.escape(expected)}\z/.match(actual),
           "Wrong at index #{index}; should be: #{expected} NOT #{actual}")
  end

  test "name search directive show instances simple" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: "name: angophora costata show-instances:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    check_results_1(search)
    check_results_2(search)
    check_results_3(search)
  end

  def check_results_1(search)
    confirm_results_class(search.executed_query.results)
    debug = false
    show_results(search) if debug
    assert_equal 9,
                 search.executed_query.results.size,
                 "Expected 9 results not #{search.executed_query.results.size}"
  end

  def check_results_2(search)
    confirm_disp(search, 0, "name_as_part_of_concept")
    confirm_name(search, 0, "Angophora costata (Gaertn.) Britten")
    confirm_disp(search, 1, "instance_as_part_of_concept")
    confirm_inst(search, 1, "Angophora costata (Gaertn.) Britten")
    confirm_disp(search, 2, "instance_as_part_of_concept")
    confirm_inst(search, 2, "Angophora costata (Gaertn.) Britten")
    confirm_disp(search, 3, "instance-is-cited-by")
    confirm_inst(search, 3, "Metrosideros costata Gaertn.")
    confirm_disp(search, 4, "instance-is-cited-by")
  end

  def check_results_3(search)
    confirm_inst(search, 4, "Metrosideros costata Gaertn.")
    confirm_disp(search, 5, "instance_as_part_of_concept")
    confirm_inst(search, 5, "Angophora costata (Gaertn.) Britten")
    confirm_disp(search, 6, "instance-is-cited-by")
    confirm_inst(search, 6, "Angophora lanceolata Cav.")
    confirm_disp(search, 7, "instance-is-cited-by")
    confirm_inst(search, 7, "Metrosideros costata Gaertn.")
  end

  def show_results(search)
    search.executed_query.results.each do |result|
      puts "#{result.id} #{result.display_as} #{name_info(result)}"
    end
  end

  def name_info(result)
    case result.display_as
    when /name_as_part_of_concept/
      result.full_name
    when /\Ainstance/
      Name.find(result.name_id).full_name
    else
      ""
    end
  end

  def confirm_disp(search, index, expected)
    actual = search.executed_query.results[index].display_as
    assert(/\A#{Regexp.escape(expected)}\z/.match(actual),
           "Wrong at index #{index}; should be: #{expected} NOT #{actual}")
  end

  def confirm_name(search, index, expected)
    actual = search.executed_query.results[index].full_name
    assert(/\A#{Regexp.escape(expected)}\z/.match(actual),
           "Wrong at index #{index}; should be: #{expected} NOT #{actual}")
  end

  def confirm_inst(search, index, expected)
    actual = Name.find(search.executed_query.results[index].name_id).full_name
    assert(/\A#{Regexp.escape(expected)}\z/.match(actual),
           "Wrong at index #{index}; should be: #{expected} NOT #{actual}")
  end
end
