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
  test "name and wrong year search" do
    ta = Instance::AsTypeahead::ForSynonymy.new("angophora costata 1789",
                                                names(:a_species).id)
    assert ta.results.instance_of?(Array), "Results should be an array."
    assert ta.results.empty?, "Results should include no records."
  end
end
