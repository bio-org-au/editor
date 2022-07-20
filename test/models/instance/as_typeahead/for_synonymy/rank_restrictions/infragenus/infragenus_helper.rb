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
def check_infrageneric_exclusions
  %w[Regio Regnum Division Classis Subclassis Superordo Ordo Subordo Familia
     Subfamilia Tribus Subtribus Species Subspecies Nothovarietas Varietas
     Subvarietas Forma Subforma].each do |rank_string|
    escaped_s = Regexp.escape(rank_string)
    assert @rank_names.select { |e| e.match(/\A#{escaped_s}\z/) }.empty?,
           "Expect no #{rank_string} to be suggested"
  end
end

def check_infrageneric_inclusions
  assert @rank_names.select { |e| e.match(/\AGenus\z/) }.size >= 5,
         "Expect correct number of genera to be suggested"
  %w(Subgenus Sectio Subsectio Series
     Subseries Superspecies [infragenus] [unranked]).each do |rank_string|
    escaped_s = Regexp.escape(rank_string)
    assert @rank_names.select { |e| e.match(/\A#{escaped_s}\z/) }.size >= 1,
           "Expect at least one #{rank_string} to be suggested"
  end
end
