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
class For_phrase_name_with_digit_search < ActiveSupport::TestCase


  def setup
    @typeahead = Instance::AsTypeahead::ForSynonymy.new("Darwinia sp. 7",
                                                        names(:a_species).id)
  end

  test "phrase name with digit search" do
    assert @typeahead.results.instance_of?(Array), "Results should be an array."
    assert @typeahead.results.size == 1,
      "Incomplete year should not be ignored and one record should be returned."
    assert @typeahead.results
                     .collect { |r| r[:value] }
                     .include?(DARWINIA_SP_7_CITATION), DARWINIA_SP_7_ERROR
  end
end
