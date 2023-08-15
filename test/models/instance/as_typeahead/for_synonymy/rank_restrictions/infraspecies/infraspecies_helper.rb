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
def check_infraspecific_exclusions
  %w[Regio Regnum Division Classis Subclassis Superordo Ordo Subordo Familia
     Subfamilia Tribus Subtribus Genus Subgenus Sectio Subsectio Series
     Subseries Superspecies].each do |rank_string|
    assert @rank_names.none? { |e| e.match(/\A#{rank_string}\z/) },
           "Expect no #{Regexp.escape(rank_string)} to be suggested"
  end
end

def check_infraspecific_inclusions
  check_species
  check_the_rest
end

def check_species
  assert @rank_names.select { |e| e == "Species" }.size >= 5,
         "Expect correct number of species to be suggested"
end

def check_the_rest
  ["Subspecies", "Nothovarietas", "Varietas", "Subvarietas", "Forma", "Subforma", "[n/a]", "[unknown]", "[unranked]",
   "[infraspecies]", "morphological var.", "nothomorph."]
    .each do |rank_string|
    matches = @rank_names.select do |e|
      e.match(/\A#{Regexp.escape(rank_string)}\z/)
    end
    assert matches.size >= 1,
           "Expect at least one #{rank_string} to be suggested"
  end
end
