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

# Nam rank options test.
class RankOptionTest < ActiveSupport::TestCase
  test "scientific ranks below family" do
    options = NameRank.options_for_category(
      name_categories(:scientific),
      NameRank.species
    )
    assert options.instance_of?(Array)
    ranks = options.collect(&:first)
    subfamily_to_genus(ranks)
    genus_to_species(ranks)
    species_to_var(ranks)
    below_var(ranks)
    the_rest(ranks)
  end

  test "scientific ranks above family" do
    options = NameRank.options_for_category(
      name_categories(:scientific),
      NameRank.family
    )
    assert options.instance_of?(Array)
    ranks = options.collect(&:first)
    family_and_above(ranks)
  end

  def family_and_above(ranks)
    assert ranks.include?("Regnum"), "Ranks should include 'Regnum'"
    assert ranks.include?("Division"), "Ranks should include 'Division'"
    assert ranks.include?("Classis"), "Ranks should include 'Classis'"
    assert ranks.include?("Subclassis"), "Ranks should include 'Subclassis'"
    assert ranks.include?("Superordo"), "Ranks should include 'Superordo'"
    assert ranks.include?("Ordo"), "Ranks should include 'Ordo'"
    assert ranks.include?("Subordo"), "Ranks should include 'Subordo'"
    assert ranks.include?("Familia"), "Ranks should include 'Familia'"
  end

  def subfamily_to_genus(ranks)
    assert ranks.include?("Subfamilia"), "Ranks should include 'Subfamilia'"
    assert ranks.include?("Tribus"), "Ranks should include 'Tribus'"
    assert ranks.include?("Subtribus"), "Ranks should include 'Subtribus'"
  end

  def genus_to_species(ranks)
    assert ranks.include?("Genus"), "Ranks should include 'Genus'"
    assert ranks.include?("Subgenus"), "Ranks should include 'Subgenus'"
    assert ranks.include?("Sectio"), "Ranks should include 'Sectio'"
    assert ranks.include?("Subsectio"), "Ranks should include 'Subsectio'"
    assert ranks.include?("Series"), "Ranks should include 'Series'"
    assert ranks.include?("Subseries"), "Ranks should include 'Subseries'"
    assert ranks.include?("Superspecies"),
           "Ranks should include 'Superspecies'"
  end

  def species_to_var(ranks)
    assert ranks.include?("Species"), "Ranks should include 'Species'"
    assert ranks.include?("Subspecies"), "Ranks should include 'Subspecies'"
    assert ranks.include?("Nothovarietas"),
           "Ranks should include 'Nothovarietas'"
  end

  def below_var(ranks)
    assert ranks.include?("Varietas"), "Ranks should include 'Varietas'"
    assert ranks.include?("Subvarietas"), "Ranks should include 'Subvarietas'"
    assert ranks.include?("Forma"), "Ranks should include 'Forma'"
    assert ranks.include?("Subforma"), "Ranks should include 'Subforma'"
  end

  def the_rest(ranks)
    assert ranks.include?("[unranked]"), "Ranks should include '[unranked]'"
    assert ranks.include?("[infrafamily]"),
           "Ranks should include '[infrafamily]'"
    assert ranks.include?("[infragenus]"), "Ranks should include '[infragenus]'"
    assert ranks.include?("[infraspecies]"),
           "Ranks should include '[infraspecies]'"
    assert ranks.include?("[n/a]"), "Ranks should include '[n/a]'"
  end
end
