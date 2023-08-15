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
#   A list of names.
class Name::AsTypeahead::ForUnpubCit
  attr_reader :suggestions,
              :params

  SEARCH_LIMIT = 50

  def initialize(params)
    @params = params
    @suggestions = @params[:term].blank? ? [] : query
  end

  def prepared_search_term
    @params[:term].tr("*", "%").downcase + "%"
  end

  def query
    Name.not_a_duplicate
        .where(["lower(full_name) like lower(?)", prepared_search_term])
        .includes(:name_status)
        .joins(:name_rank)
        .order("name_rank.sort_order, lower(full_name)")
        .limit(SEARCH_LIMIT)
        .collect do |n|
      { value: "#{n.full_name} - #{n.name_status.name}", id: n.id }
    end
  end
end
