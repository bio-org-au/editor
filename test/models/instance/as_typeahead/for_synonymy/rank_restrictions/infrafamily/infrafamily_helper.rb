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

def check_infrafamily_exclusions
  %w[Regio Regnum Division Classis Subclassis Superordo Ordo Subordo Genus
     Subgenus Sectio Subsectio Series Subseries Superspecies Species
     Subspecies Nothovarietas Varietas
     Subvarietas Forma Subforma].each do |rank_string|
    escape_s = Regexp.escape(rank_string)
    assert @rank_names.none? { |e| e.match(/\A#{escape_s}\z/) },
           "Expect no #{rank_string} to be suggested"
  end
end

def check_infrafamily_inclusions
  %w(Familia Subfamilia Tribus Subtribus
     [infrafamily] [unranked]).each do |rank_string|
    escape_s = Regexp.escape(rank_string)
    assert @rank_names.select { |e| e.match(/\A#{escape_s}\z/) }.size >= 1,
           "Expect one #{rank_string} to be suggested"
  end
end
