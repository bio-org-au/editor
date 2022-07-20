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
require "models/instance/as_typeahead/for_synonymy/test_helper"

# Single instance typeahead search.
class ForNameAndReferenceYearTest < ActiveSupport::TestCase
  test "year and name search" do
    ta = Instance::AsTypeahead::ForSynonymy.new("1916 angophora costata",
                                                names(:a_species).id)
    assert ta.results.instance_of?(Array), "Results should be an array."
    assert ta.results.size == 1, "Results should include just one record."
    assert ta.results
             .collect { |r| r[:value] }
             .include?(ANGOPHORA_COSTATA_JOURNAL_1916_STRING),
           ANGOPHORA_COSTATA_JOURNAL_1916_ERROR
  end
end
