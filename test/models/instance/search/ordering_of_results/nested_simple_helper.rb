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

def test1
  assert_with_args(@results, 0, "xx,20,900 - Metrosideros costata Gaertn.")
  assert_with_args(@results, 1, "3 - Angophora costata (Gaertn.) Britten")
  assert_with_args(@results, 2, "xx 1 - Metrosideros costata Gaertn.")
  assert_with_args(@results, 3, "2 - Metrosideros costata Gaertn.")
  assert_with_args(@results, 4,
                   "zzzz99902 - Casuarina inophloia F.Muell. & F.M.Bailey")
end

def test2
  assert_with_args(@results, 5,
                   "zzzz99901 - Casuarina inophloia F.Muell. & F.M.Bailey")
  assert_with_args(@results, 6, "zzzz99904 - a genus with one instance")
  assert_with_args(@results, 7, "zzzz99905 - a genus with two instances")
  assert_with_args(@results, 8,
                   "zzzz99903 - Casuarina inophloia F.Muell. & F.M.Bailey")
end

def test3
  assert_with_args(@results, 9, "zzzz99907 - has two instances the same")
  assert_with_args(@results, 10, "zzzz99907 - has two instances the same")
  assert_with_args(@results, 11,
                   "xx 15 - Angophora costata (Gaertn.) Britten")
  assert_with_args(@results, 12, "xx,20,1000 - Metrosideros costata Gaertn.")
  assert_with_args(@results, 13, "146 - Angophora costata (Gaertn.) Britten")
end

def test4
  assert_with_args(@results, 14, "xx,20,600 - Angophora lanceolata Cav.")
  assert_with_args(@results, 15, "xx,20,700 - Metrosideros costata Gaertn.")
  assert_with_args(@results, 17, "zzzz99913b - name one for eflora")
  assert_with_args(@results, 18, "zzzz99913c - name one for eflora")
  assert_with_args(@results, 19, "zzzz99913d - name one for eflora")
  assert_with_args(@results, 20, "zzzz99913a - name one for eflora")
end

def test5
  assert_with_args(@results, 21, "zzzz99913e - name one for eflora")
  assert_with_args(@results, 22, "xx 200,300 - Triodia basedowii E.Pritz")
  assert_with_args(@results, 23, "zzzz99906 - a genus with two instances")
  assert_with_args(@results, 24,
                   "zzzz99901 - a an infrafamily with an instance")
  assert_with_args(@results, 25,
                   "zzzz99901 - a an infragenus with an instance")
  assert_with_args(@results, 26,
                   "zzzz99901 - a an infraspecies with an instance")
  assert_with_args(@results, 27, "zzzz99901 - a an na with an instance")
end

def test6
  assert_with_args(@results, 28, "999 - a an unknown with an instance")
  assert_with_args(@results, 29, "999 - a an unranked with an instance")
  assert_with_args(@results, 30, "999 - a duplicate genus")
  assert_with_args(@results, 31, "999 - a morphological var with an instance")
  assert_with_args(@results, 32, "999 - a nothomorph with an instance")
  assert_with_args(@results, 33, "999 - a_family")
  assert_with_args(@results, 34, "999 - a_forma")
  assert_with_args(@results, 35, "999 - a_genus")
  assert_with_args(@results, 36, "999 - a_nothovarietas")
end

def test7
  assert_with_args(@results, 37, "999 - a_sectio")
  assert_with_args(@results, 38, "999 - a_series")
  assert_with_args(@results, 39, "999 - a_species")
  assert_with_args(@results, 40, "74, t. 100 - a_subclassis")
  assert_with_args(@results, 41, "999 - a_subfamilia")
  assert_with_args(@results, 42, "999 - a_subforma")
  assert_with_args(@results, 43, "999 - a_subgenus")
  assert_with_args(@results, 44, "999 - a_subordo")
end

def test8
  assert_with_args(@results, 45, "999 - a_subsectio")
  assert_with_args(@results, 46, "999 - a_subseries")
  assert_with_args(@results, 47, "999 - a_subspecies")
  assert_with_args(@results, 48, "999 - a_subtribus")
  assert_with_args(@results, 49, "999 - a_subvarietas")
end

def test9
  assert_with_args(@results, 50, "74, t. 99 - a_superordo")
  assert_with_args(@results, 51, "999 - a_superspecies")
  assert_with_args(@results, 52, "999 - a_tribus")
  assert_with_args(@results, 53, "999 - a_varietas")
  assert_with_args(@results, 54, "999 - an_ordo")
end

def test10
  assert_with_args(@results,
                   55,
                   "57-58 - dummy_name_2")
  assert_with_args(@results,
                   56,
                   "57 - dummy_name_3")
  assert_with_args(@results,
                   57,
                   "75, t. 101 - Magnoliophyta Cronquist, Takht. & W.Zimm. ex Reveal a_division")
  assert_with_args(@results,
                   58,
                   "75, t. 102 - Magnoliopsida Brongn. a_classis")
  assert_with_args(@results, 59, "76 - Metrosideros costata Gaertn.")
  assert_with_args(@results, 60, "9999999999 - orth var for tax nov")
  assert_with_args(@results, 61, "19-20 - Plantae Haeckel")
end
