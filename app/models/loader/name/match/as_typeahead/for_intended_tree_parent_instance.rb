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

# Provide typeahead suggestions based on a search term.
#
# Offer parents
# Only accepted names
class Loader::Name::Match::AsTypeahead::ForIntendedTreeParentInstance
  attr_reader :suggestions,
              :params

  SEARCH_LIMIT = 50

  def initialize(params)
    @params = params
    @suggestions =
      if @params[:term].blank?
        []
      else
        query
      end
  end

  def prepared_search_term
    @params[:term].tr("*", "%").downcase + "%"
  end

  # Select on full name
  # Show full name and name status (unless 'legitimate')
  def core_query
    Name.joins(:name_rank)
        .joins(:name_status)
        .joins(:name_type)
        .where(['lower(f_unaccent(name.full_name)) like lower(f_unaccent(?))',
                prepared_search_term])
        .where("name_type.name = 'scientific'")
        .select("name.id, name.full_name, case name_status.name when 'legitimate' then null else name_status.name end as status")
        .order("name_rank.sort_order, name.full_name")
        .limit(SEARCH_LIMIT)
  end

  def query
    @qry = core_query
    @qry = @qry.collect do |qry|
      { value: "#{qry.full_name} #{qry.status}",
        id: qry.id }
    end
  end
end
