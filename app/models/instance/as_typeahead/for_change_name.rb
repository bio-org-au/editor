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
# Returns names matching the search term, filtered to the same name_type and
# name_rank as the instance's current name. Used when changing the name on a
# draft standalone instance.
class Instance::AsTypeahead::ForChangeName
  attr_reader :suggestions

  SEARCH_LIMIT = 50

  def initialize(term:, name_type_id:, name_rank_id:, exclude_name_id:)
    @suggestions = term.blank? ? [] : query(term, name_type_id, name_rank_id, exclude_name_id)
  end

  private

  def query(term, name_type_id, name_rank_id, exclude_name_id)
    Name.not_a_duplicate
        .where("lower(full_name) like lower(?)", term.tr("*", "%") + "%")
        .where(name_type_id: name_type_id, name_rank_id: name_rank_id)
        .where.not(id: exclude_name_id)
        .joins(:name_rank)
        .order("name_rank.sort_order, lower(full_name)")
        .limit(SEARCH_LIMIT)
        .map { |n| { value: n.full_name, id: n.id } }
  end
end
