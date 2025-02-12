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
# == Schema Information
#
# Table name: name_rank
#
#  id                :bigint           not null, primary key
#  abbrev            :string(20)       not null
#  deprecated        :boolean          default(FALSE), not null
#  description_html  :text
#  display_name      :text             not null
#  has_parent        :boolean          default(FALSE), not null
#  italicize         :boolean          default(FALSE), not null
#  lock_version      :bigint           default(0), not null
#  major             :boolean          default(FALSE), not null
#  name              :string(50)       not null
#  sort_order        :integer          default(0), not null
#  use_verbatim_rank :boolean          default(FALSE), not null
#  visible_in_name   :boolean          default(TRUE), not null
#  name_group_id     :bigint           not null
#  parent_rank_id    :bigint
#  rdf_id            :string(50)
#
# Indexes
#
#  name_rank_rdfid  (rdf_id)
#  nr_unique_name   (name_group_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_p3lpayfbl9s3hshhoycfj82b9  (name_group_id => name_group.id)
#  fk_r67um91pujyfrx7h1cifs3cmb  (parent_rank_id => name_rank.id)
#
class NameRank < ActiveRecord::Base
  self.table_name = "name_rank"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  has_many :names
  belongs_to :name_group

  GENUS = "Genus"
  SUBGENUS = "Subgenus"
  SECTIO = "Sectio"
  SUBSECTIO = "Subsectio"
  SERIES = "Series"
  SUBSERIES = "Subseries"
  SUPERSPECIES = "Superspecies"

  FAMILIA = "Familia"
  FAMILY = FAMILIA
  SUBFAMILIA = "Subfamilia"
  TRIBUS = "Tribus"
  SUBTRIBUS = "Subtribus"

  SPECIES = "Species"
  SUBSPECIES = "Subspecies"
  NOTHOVARIETAS = "Nothovarietas"
  VARIETAS = "Varietas"
  SUBVARIETAS = "Subvarietas"
  FORMA = "Forma"
  SUBFORMA = "Subforma"

  MORPHOLOGICAL_VAR = "morphological var."
  NOTHOMORPH = "nothomorph."

  NA = "[n/a]"
  UNRANKED = "[unranked]"
  INFRAFAMILY = "[infrafamily]"
  INFRAGENUS = "[infragenus]"
  INFRASPECIES = "[infraspecies]"

  scope :not_deprecated, -> { where(deprecated: false) }

  scope :infraspecific,
        (lambda do
          where("(name_rank.sort_order >= (select iga.sort_order
                                             from name_rank iga
                                            where name = 'Species')
                  and
                  name_rank.sort_order <= (select species.sort_order
                                             from name_rank species
                                            where name = 'nothomorph.') )
                  or name_rank.name = '[infraspecies]'
                  or name_rank.name = '[n/a]'
                  or name_rank.name = '[unknown]'
                  or name_rank.name = '[unranked]' ")
        end)

  scope :infrageneric,
        (lambda do
          where("(name_rank.sort_order >= (select iga.sort_order
                                             from name_rank iga
                                            where name = 'Genus')
                  and
                  name_rank.sort_order < (select species.sort_order
                                            from name_rank species
                                           where name = 'Species') )
                  or name_rank.name = '[infragenus]'
                  or name_rank.name = '[unranked]' ")
        end)

  scope :infrafamilial,
        (lambda do
          where("(name_rank.sort_order >= (select iga.sort_order
                                             from name_rank iga
                                            where name = 'Familia')
                  and
                  name_rank.sort_order < (select species.sort_order
                                            from name_rank species
                                           where name = 'Genus') )
                 or name_rank.name = '[infrafamily]'
                 or name_rank.name = '[unranked]' ")
        end)

  def self.default
    NameRank.where(name: "Species").push(NameRank.first).first
  end

  def self.options_for_category(name_category = :unknown, rank)
    case name_category
    when NameCategory::CULTIVAR_HYBRID_CATEGORY
      cultivar_hybrid_options
    when NameCategory::CULTIVAR_CATEGORY
      cultivar_options
    else
      if rank.below_family?
        below_family_options
      else
        above_family_options
      end
    end
  end

  def self.options
    where("deprecated is false")
      .order(:sort_order)
      .collect { |rank| [rank.display_name, rank.id] }
  end

  def self.query_form_options
    where("deprecated is false")
      .order(:sort_order)
      .collect { |n| [n.name, "rank: #{n.name.downcase}"] }
  end

  def self.query_form_ranked_below_options
    where("deprecated is false")
      .order(:sort_order)
      .collect { |n| [n.name, "below-rank: #{n.name.downcase}"] }
  end

  def self.xquery_form_ranked_above_options
    where("deprecated is false")
      .order(:sort_order)
      .collect { |n| [n.name, "above-rank: #{n.name.downcase}"] }
  end

  def self.cultivar_hybrid_options
    where("deprecated is false")
      .where("(name not like '%[%' or name = '[unranked]') ")
      .where(" sort_order >= (select sort_order from name_rank where lower(name)
    = 'species')")
      .order(:sort_order)
      .collect { |rank| [rank.display_name, rank.id] }
  end

  def self.cultivar_options
    where("deprecated is false")
      .where("name not like '%[%' or name = '[unranked]' ")
      .where(" sort_order >= (select sort_order from name_rank where lower(name)
    = 'species')")
      .order(:sort_order)
      .collect { |rank| [rank.display_name, rank.id] }
  end

  def self.below_family_options
    where("deprecated is false")
      .where(" sort_order > (select sort_order from name_rank where lower(name) = 'familia')")
      .order(:sort_order)
      .collect { |rank| [rank.display_name, rank.id] }
  end

  def self.above_family_options
    where("deprecated is false")
      .where(" sort_order <= (select sort_order from name_rank where lower(name) = 'familia')")
      .order(:sort_order)
      .collect { |rank| [rank.display_name, rank.id] }
  end

  def self.id_is_unranked?(id)
    candidate = NameRank.find_by(id: id)
    candidate.present? && candidate.name == "[unranked]"
  end

  def deprecated?
    deprecated
  end

  def family?
    !name.match(/\A#{FAMILY}\z/).nil?
  end

  def species?
    !name.match(/\A#{SPECIES}\z/).nil?
  end

  def genus?
    !name.match(/\A#{GENUS}\z/).nil?
  end

  def self.not_applicable
    find_by(name: NA).id
  end

  def na?
    !name.match(/\A#{Regexp.escape(NA)}\z/).nil?
  end

  def unranked?
    !name.match(/\A#{Regexp.escape(UNRANKED)}\z/).nil?
  end

  def infrafamily?
    !name.match(/\A#{Regexp.escape(INFRAFAMILY)}\z/).nil?
  end

  def infragenus?
    !name.match(/\A#{Regexp.escape(INFRAGENUS)}\z/).nil?
  end

  def infraspecies?
    uname.match(/\A#{Regexp.escape(INFRASPECIES)}\z/).nil?
  end

  def infraspecific?
    [SPECIES, SUBSPECIES, NOTHOVARIETAS, VARIETAS, SUBVARIETAS, FORMA, SUBFORMA,
     INFRASPECIES, NOTHOMORPH, MORPHOLOGICAL_VAR].include?(name)
  end

  def infrageneric?
    [GENUS, SUBGENUS, SECTIO, SUBSECTIO, SERIES, SUBSERIES, SUPERSPECIES,
     INFRAGENUS].include?(name)
  end

  def infrafamilial?
    [FAMILIA, SUBFAMILIA, TRIBUS, SUBTRIBUS, INFRAFAMILY].include?(name)
  end

  def self.genus
    NameRank.find_by(name: GENUS)
  end

  def parent
    if deprecated?
      DeprecatedNoParent.new
    elsif na?
      NoParent.new
    elsif below_family?
      parent_of_below_family
    else
      NoParent.new
    end
  end

  def parent_of_below_family
    if below_species?
      NameRank.species
    elsif below_genus?
      NameRank.genus
    elsif genus?
      NameRank.family
    else
      NameRank.family
    end
  end

  # NOTE: greater than means below!
  def below_species?
    sort_order > NameRank.species.sort_order
  end

  # NOTE: greater than means below!
  def below_genus?
    sort_order > NameRank.genus.sort_order
  end

  # NOTE: greater than means below!
  def below_family?
    sort_order > NameRank.family.sort_order
  end

  def self.species
    find_by(name: SPECIES)
  end

  def self.family
    find_by(name: FAMILY)
  end

  def takes_parent?
    unranked? || parent.real_parent?
  end

  def real_parent?
    true
  end

  def takes_any_parent?
    unranked?
  end

  def above?(other_name_rank)
    sort_order < other_name_rank.sort_order
  end

  def top_rank?
    sort_order == NameRank.minimum(:sort_order)
  end
end

# A stand-in class when there is no parent.
class NoParent
  def name
    "No parent"
  end

  def real_parent?
    false
  end

  def id
    -1
  end
end

# A stand-in class when parent is unknown
class UnknownParent < NoParent
  def name
    "Unknown parent"
  end
end

# A stand-in class when no parent because deprecated
class DeprecatedNoParent < NoParent
  def name
    "No parent because deprecated"
  end
end
