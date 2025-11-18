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

# Rails class for the Name Category table.
# == Schema Information
#
# Table name: name_category
#
#  id                            :bigint           not null, primary key
#  description_html              :text
#  lock_version                  :bigint           default(0), not null
#  max_parents_allowed           :integer          default(0), not null
#  min_parents_required          :integer          default(0), not null
#  name                          :string(50)       not null
#  parent_1_help_text            :text
#  parent_2_help_text            :text
#  requires_family               :boolean          default(FALSE), not null
#  requires_higher_ranked_parent :boolean          default(FALSE), not null
#  requires_name_element         :boolean          default(FALSE), not null
#  sort_order                    :integer          default(0), not null
#  takes_author_only             :boolean          default(FALSE), not null
#  takes_authors                 :boolean          default(FALSE), not null
#  takes_cultivar_scoped_parent  :boolean          default(FALSE), not null
#  takes_hybrid_scoped_parent    :boolean          default(FALSE), not null
#  takes_name_element            :boolean          default(FALSE), not null
#  takes_rank                    :boolean          default(FALSE), not null
#  takes_verbatim_rank           :boolean          default(FALSE), not null
#  rdf_id                        :string(50)
#
# Indexes
#
#  name_category_rdfid           (rdf_id)
#  uk_rxqxoenedjdjyd4x7c98s59io  (name) UNIQUE
#
class NameCategory < ApplicationRecord
  self.table_name = "name_category"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  SCIENTIFIC_CATEGORY = "scientific"
  SCIENTIFIC_HYBRID_FORMULA_CATEGORY = "scientific hybrid formula"
  SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY =
    "scientific hybrid formula unknown 2nd parent"
  PHRASE_NAME = "phrase name"
  CULTIVAR_CATEGORY = "cultivar"
  CULTIVAR_HYBRID_CATEGORY = "cultivar hybrid"
  OTHER_CATEGORY = "other"

  has_many :name_types
  def self.phrase_name
    where("name = 'phrase name'").first
  end

  def needs_top_buttons?
    scientific?
  end

  def scientific?
    name == SCIENTIFIC_CATEGORY
  end

  def scientific_hybrid_formula?
    name == SCIENTIFIC_HYBRID_FORMULA_CATEGORY
  end

  def scientific_hybrid_formula_unknown_2nd_parent?
    name == SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY
  end

  def cultivar?
    name == CULTIVAR_CATEGORY
  end

  def cultivar_hybrid?
    name == CULTIVAR_HYBRID_CATEGORY
  end

  def phrase_name?
    name == PHRASE_NAME
  end

  def other?
    name == OTHER_CATEGORY
  end

  # count the types?
  def only_one_type?
    name_types.size == 1
  end

  def takes_rank?
    takes_rank
  rescue StandardError => e
    # transitional code
    Rails.logger.error("Falling back to static takes_rank criteria because name_category.takes_rank was not found")
    scientific? ||
      scientific_hybrid_formula? ||
      cultivar? ||
      cultivar_hybrid? ||
      phrase_name?
  end

  def takes_authors?
    takes_authors
  end

  def takes_author_only?
    takes_author_only
  end

  def takes_name_element?
    takes_name_element
  end

  def requires_parent_1?
    min_parents_required > 0
  end

  def requires_parent_2?
    min_parents_required > 1
  end

  def requires_name_element?
    requires_name_element
  end

  def requires_higher_ranked_parent?
    requires_higher_ranked_parent
  end

  def takes_cultivar_scoped_parent?
    takes_cultivar_scoped_parent
  end

  def takes_hybrid_scoped_parent?
    takes_hybrid_scoped_parent
  end

  def takes_verbatim_rank?
    takes_verbatim_rank
  end

  def takes_parent_1?
    max_parents_allowed > 0
  end

  def takes_parent_2?
    max_parents_allowed > 1
  end
end
