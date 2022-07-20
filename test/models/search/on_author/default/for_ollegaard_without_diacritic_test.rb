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

# Search model test for special character.
class SOADefault4OllegaardWithoutDiacriticTest < ActiveSupport::TestCase
  test "author search on name for ollegaard without diacritic" do
    params = ActiveSupport::HashWithIndifferentAccess.new(query_target:
                                                          "author",
                                                          query_string:
                                                          "Ollegaard",
                                                          current_user:
                                                          build_edit_user)
    search = Search::Base.new(params)
    assert search.executed_query.results.is_a?(ActiveRecord::Relation),
           "Results should be an ActiveRecord::Relation."
    assert_equal 2,
                 search.executed_query.results.size,
                 "Exactly 2 results expected"
    ids = search.executed_query.results.map(&:id)
    assert ids.include?(authors(:ollegaard_without_diacritic).id),
           "Expecting ollegaard without diacritic"
    assert ids.include?(authors(:ollegaard_with_leading_diacritic).id),
           "Expecting ollegaard with leading diacritic"
  end
end
