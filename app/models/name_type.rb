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
# Table name: name_type
#
#  id               :bigint           not null, primary key
#  autonym          :boolean          default(FALSE), not null
#  connector        :string(1)
#  cultivar         :boolean          default(FALSE), not null
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  formula          :boolean          default(FALSE), not null
#  hybrid           :boolean          default(FALSE), not null
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  scientific       :boolean          default(FALSE), not null
#  sort_order       :integer          default(0), not null
#  vernacular       :boolean          default(FALSE), not null
#  name_category_id :bigint           not null
#  name_group_id    :bigint           not null
#  rdf_id           :string(50)
#
# Indexes
#
#  name_type_rdfid  (rdf_id)
#  nt_unique_name   (name_group_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_10d0jlulq2woht49j5ccpeehu  (name_category_id => name_category.id)
#  fk_5r3o78sgdbxsf525hmm3t44gv  (name_group_id => name_group.id)
#
class NameType < ActiveRecord::Base
  self.table_name = "name_type"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  scope :not_deprecated, -> { where(deprecated: false) }

  has_many :names
  belongs_to :name_group
  belongs_to :name_category

  def full_name
    if parent
      "#{parent.full_name} #{name}"
    else
      name
    end
  end

  def capitalised_name
    case name
    when /\bacra\b/
      name.gsub(/\bacra\b/, "ACRA")
    when /\bpbr\b/
      name.gsub(/\bpbr\b/, "PBR")
    when /\btrade\b/
      name.gsub(/\btrade\b/, "Trade")
    else
      name
    end
  end

  def self.query_form_options
    not_deprecated.sort_by(&:name)
                  .collect { |n| [n.capitalised_name, n.name.to_s, { class: "" }] }
                  .unshift(["Include common, cultivars", "type:*"])
                  .unshift(["Exclude common, cultivars", ""])
  end

  def self.options
    all.sort_by(&:name)
       .collect { |n| [n.capitalised_name, n.id, { class: "" }] }
  end

  def self.option_ids_for_category(name_category)
    NameType.options_for_category(name_category).collect(&:second)
  end

  def self.xoptions_for_category(for_category)
    case for_category
    when Name.name_category.scientific?
      scientific_1_parent_options
    when Name.name_category.scientific_hybrid_formula?
      scientific_2_parent_options
    when Name.name_category.scientific_hybrid_formula_unknown_2nd_parent?
      scientific_hybrid_formula_unknown_2nd_parent_options
    when Name.name_category.cultivar_hybrid?
      cultivar_hybrid_options
    when Name.name_category.cultivar?
      cultivar_options
    when Name.name_category.phrase_name?
      phrase_options
    when Name.name_category.other?
      other_options
    when "all"
      options
    else
      []
    end
  end

  def self.options_for_category(for_category)
    if for_category.scientific?
      scientific_1_parent_options
    elsif for_category.scientific_hybrid_formula?
      scientific_2_parent_options
    elsif for_category.scientific_hybrid_formula_unknown_2nd_parent?
      scientific_hybrid_formula_unknown_2nd_parent_options
    elsif for_category.cultivar_hybrid?
      cultivar_hybrid_options
    elsif for_category.cultivar?
      cultivar_options
    elsif for_category.phrase_name?
      phrase_options
    elsif for_category.other?
      other_options
    # when "all"
    #   options
    else
      []
    end
  end

  def self.scientific_1_parent_options
    where(scientific: true)
      .where(" (not hybrid or name in ('named hybrid','named hybrid autonym'))")
      .where(" name != 'phrase name' ")
      .sort_by(&:name).collect { |n| [n.name, n.id] }
  end

  def self.scientific_2_parent_options
    where(" name in ('cultivar hybrid formula', 'graft/chimera')
          or (scientific and hybrid and name not in
          ('hybrid formula unknown 2nd parent','named hybrid',
          'named hybrid autonym'))")
      .sort_by(&:name).collect { |n| [n.name, n.id] }
  end

  def self.scientific_hybrid_formula_unknown_2nd_parent_options
    where(" name in ('hybrid formula unknown 2nd parent')")
      .sort_by(&:name).collect { |n| [n.name, n.id] }
  end

  def self.phrase_options
    n = find_by(name: "phrase name")
    [[n.name, n.id]]
  end

  def self.cultivar_hybrid_options
    where(scientific: false)
      .where(deprecated: false)
      .where(cultivar: true)
      .where(hybrid: true)
      .where(" name not in ('cultivar hybrid formula', 'graft/chimera')")
      .sort_by(&:name)
      .collect do |n|
      [n.name, n.id, { class: "cultivar_hybrid" }]
    end
  end

  def self.cultivar_options
    where(scientific: false)
      .where(deprecated: false)
      .where(cultivar: true)
      .where(hybrid: false)
      .where(" name not in ('cultivar hybrid formula', 'graft/chimera')")
      .sort_by(&:name)
      .collect do |n|
      [n.name, n.id, { class: "cultivar" }]
    end
  end

  def self.other_options
    where(scientific: false).where(cultivar: false)
                            .sort_by(&:name)
                            .collect do |n|
      [n.name, n.id, { class: "other" }]
    end
  end

  def hybrid?
    hybrid
  end

  def cultivar?
    cultivar
  end

  def scientific?
    scientific == true
  end

  def phrase_name?
    name == "phrase name"
  end

  def xcategory
    case name
    when "[default]"                         then "other"
    when "[unknown]"                         then "other"
    when "[n/a]"                             then "other"
    when "scientific"                        then "scientific_1_parent"
    when "phrase name"                       then "scientific_1_parent"
    when "sanctioned"                        then "scientific_1_parent"
    when "hybrid"                            then "scientific_2_parents"
    when "hybrid formula parents known"      then "scientific_2_parents"
    when "hybrid formula unknown 2nd parent" then "scientific_1_parent"
    when "named hybrid"                      then "scientific_1_parent"
    when "named hybrid autonym"              then "scientific_1_parent"
    when "hybrid autonym"                    then "scientific_2_parents"
    when "intergrade"                        then "scientific_2_parents"
    when "autonym"                           then "scientific_1_parent"
    when "cultivar"                          then "cultivar"
    when "cultivar hybrid"                   then "cultivar"
    when "cultivar hybrid formula"           then "scientific_2_parents"
    when "acra"                              then "cultivar"
    when "acra hybrid"                       then "cultivar"
    when "pbr"                               then "cultivar"
    when "pbr hybrid"                        then "cultivar"
    when "trade"                             then "cultivar"
    when "trade hybrid"                      then "cultivar"
    when "graft/chimera"                     then "scientific_2_parents"
    when "informal"                          then "other"
    when "common"                            then "other"
    else "other"
    end
  end
end
