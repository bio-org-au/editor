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
                       .joins("inner join name_status ns on name.name_status_id = ns.id")
                       .joins("inner join instance cites on instance.cites_id = cites.id")
                       .joins("inner join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
                       .where.not(page: "exclude-from-ordering-test")
                       .in_synonymy_order
                       .order(Arel.sql('reference.iso_publication_date,lower(name.full_name) collate "C"'))
                       .order(Arel.sql("instance_type.name")) # make test order definitive
    # how does having .order statements here help to test the app?
  end

  test "instances in synonymy order" do
    skip "doesn't handle new version of the in_synonymy_order - seems to be for testing page and rank ordering, needs review"
    # Very useful debug
    @results.each_with_index do |i, ndx|
      puts "#{ndx}: #{i.page} - #{i.name.full_name}"
    end
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

#  Unordered data returned October 2023

#   0: 3 - Angophora costata (Gaertn.) Britten
#   1: xx 1 - Metrosideros costata Gaertn.
#   2: 2 - Metrosideros costata Gaertn.
#   3: 41 - Rusty Gum
#   4: zzzz99902 - Casuarina inophloia F.Muell. & F.M.Bailey
#   5: zzzz99901 - Casuarina inophloia F.Muell. & F.M.Bailey
#   6: zzzz99904 - a genus with one instance
#   7: zzzz99905 - a genus with two instances
#   8: zzzz99903 - Casuarina inophloia F.Muell. & F.M.Bailey
#   9: zzzz99907 - has two instances the same
#   10: zzzz99907 - has two instances the same
#   11: xx 15 - Angophora costata (Gaertn.) Britten
#   12: xx,20,900 - Metrosideros costata Gaertn.
#   13: xx,20,1000 - Metrosideros costata Gaertn.
#   14: 40 - nothing
#   15: 146 - Angophora costata (Gaertn.) Britten
#   16: xx,20,600 - Angophora lanceolata Cav.
#   17: xx,20,700 - Metrosideros costata Gaertn.
#   18: zzzz99910 - Rusty Gum
#   19: zczzzzzzzzzzz99999999999999 - dummy_name_2
#   20: zzzz99913b - name one for eflora
#   21: zzzz99913c - name one for eflora
#   22: zzzz99913d - name one for eflora
#   23: zzzz99913a - name one for eflora
#   24: zzzz99913e - name one for eflora
#   25: xx 200,300 - Triodia basedowii E.Pritz
#   26: zzzz99906 - a genus with two instances
#   27: zzzz99901 - a an infrafamily with an instance
#   28: zzzz99901 - a an infragenus with an instance
#   29: zzzz99901 - a an infraspecies with an instance
#   30: zzzz99901 - a an na with an instance
#   31: 999 - a an unknown with an instance
#   32: 999 - a an unranked with an instance
#   33: 999 - a duplicate genus
#   34: 999 - a morphological var with an instance
#   35: 999 - a nothomorph with an instance
#   36: 999 - a_family
#   37: 999 - a_forma
#   38: 999 - a_genus
#   39: 999 - a_nothovarietas
#   40: 999 - a_sectio
#   41: 999 - a_series
#   42: 999 - a_species
#   43: 74, t. 100 - a_subclassis
#   44: 999 - a_subfamilia
#   45: 999 - a_subforma
#   46: 999 - a_subgenus
#   47: 999 - a_subordo
#   48: 999 - a_subsectio
#   49: 999 - a_subseries
#   50: 999 - a_subspecies
#   51: 999 - a_subtribus
#   52: 999 - a_subvarietas
#   53: 74, t. 99 - a_superordo
#   54: 999 - a_superspecies
#   55: 999 - a_tribus
#   56: 999 - a_varietas
#   57: 999 - an_ordo
#   58: 57-58 - dummy_name_2
#   59: 57 - dummy_name_3
#   60: 75, t. 101 - Magnoliophyta Cronquist, Takht. & W.Zimm. ex Reveal a_division
#   61: 75, t. 102 - Magnoliopsida Brongn. a_classis
#   62: 76 - Metrosideros costata Gaertn.
#   63: 9999999999 - orth var for tax nov
#   64: 19-20 - Plantae Haeckel
#
#
