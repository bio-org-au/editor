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

# Name - for new Names.
class Name::AsNew < Name
  def self.scientific
    name = Name.new
    name.name_type_id = NameType.find_by(name: "scientific").id
    name.name_rank_id = NameRank.find_by(name: "Species").id
    name.name_status_id = NameStatus.find_by(name: "legitimate").id
    name
  end

  def self.scientific_family_or_above
    name = Name.new
    name.name_type_id = NameType.find_by(name: "scientific").id
    name.name_rank_id = NameRank.find_by(name: "Familia").id
    name.name_status_id = NameStatus.find_by(name: "legitimate").id
    name
  end

  def self.phrase
    name = Name.new
    name.name_type_id = NameType.find_by(name: "phrase name").id
    name.name_rank_id = NameRank.find_by(name: "Species").id
    name.name_status_id = NameStatus.find_by(name: "[n/a]").id
    name
  end

  def self.scientific_hybrid
    name = Name.new
    name.name_type_id = NameType
                        .find_by(name: "hybrid formula parents known")
                        .id
    name.name_rank_id = NameRank.find_by(name: "Species").id
    name.name_status_id = NameStatus.find_by(name: "[n/a]").id
    name
  end

  def self.scientific_hybrid_unknown_2nd_parent
    name = Name.new
    name.name_type_id = NameType
                        .find_by(name: "hybrid formula unknown 2nd parent")
                        .id
    name.name_rank_id = NameRank.find_by(name: "[n/a]").id
    name.name_status_id = NameStatus.find_by(name: "[n/a]").id
    name
  end

  def self.cultivar_hybrid
    name = Name.new
    name.name_type_id = NameType.find_by(name: "cultivar hybrid").id
    name.name_rank_id = NameRank.find_by(name: "[unranked]").id
    name.name_status = NameStatus.not_applicable
    name
  end

  def self.cultivar
    name = Name.new
    name.name_type_id = NameType.find_by(name: "cultivar").id
    name.name_rank_id = NameRank.find_by(name: "[unranked]").id
    name.name_status = NameStatus.not_applicable
    name
  end

  def self.other
    name = Name.new
    name.name_type_id = NameType.find_by(name: "common").id
    name.name_rank_id = NameRank.not_applicable
    name.name_status = NameStatus.not_applicable
    name
  end
end
