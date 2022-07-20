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
require "models/instance/as_typeahead/for_synonymy/rank_restrictions/\
above_family/above_family_helper"

# Single instance typeahead search.
class TypeaheadForSynonymySuperordoTest < ActiveSupport::TestCase
  def setup
    @ta = Instance::AsTypeahead::ForSynonymy.new("a*",
                                                 names(:a_superordo).id)
    @tb = Instance::AsTypeahead::ForSynonymy.new("plantae",
                                                 names(:a_superordo).id)
    @tc = Instance::AsTypeahead::ForSynonymy.new("magnolio",
                                                 names(:a_superordo).id)
  end

  test "instance typeahead for synonymy rank restriction for a superordo" do
    assert @ta.results.size >= 2, "Should be at least 2 synonyms"
    @rank_names = @ta.results.collect do |result|
      Instance.find(result[:id]).name.name_rank.name
    end
    inclusions = NameRank.where(deprecated: false).collect(&:name)
    inclusions.delete("Regnum")
    inclusions.delete("Division")
    inclusions.delete("Classis")
    check_rank_names_inclusions(inclusions)
  end

  test "instance typeahead for synonymy rank restriction superordo regnum" do
    assert @tb.results.size >= 1, "Should be at least 1 synonym"
    @rank_names = @tb.results.collect do |result|
      Instance.find(result[:id]).name.name_rank.name
    end
    check_rank_names_inclusions(["Regnum"])
  end

  test "instance typeahead for synonymy rank restriction superordo division" do
    assert @tc.results.size >= 1, "Should be at least 1 synonym"
    @rank_names = @tc.results.collect do |result|
      Instance.find(result[:id]).name.name_rank.name
    end
    check_rank_names_inclusions(%w[Division Classis])
  end
end
