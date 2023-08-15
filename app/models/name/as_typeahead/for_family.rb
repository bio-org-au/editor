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
# Offer parents of the appropriate rank:
# - infra-species (below species)   : rank must be above the name's rank
#                                     and equal to or below species rank
# - species                         : any rank above species and equal to
#                                     or below genus
# - genus, above genus, below family: rank must be above the name's rank
#                                     and equal to or below family
# - family and above                : any rank above the name's rank
# - [unranked]                      : [unranked] and any non-deprecated
#                                     rank above [unranked]
#
# Exclude names marked as duplicates.
# Show an instance count for each result.
class Name::AsTypeahead::ForFamily
  attr_reader :suggestions,
              :params

  SEARCH_LIMIT = 50
  GROUP_BY = "name.id,name.full_name,name_rank.name,name_status.name," \
             "name_rank.sort_order"

  def initialize(params)
    @params = params
    @suggestions = if @params[:term].blank?
                     []
                   else
                     query
                   end
  end

  def prepared_search_term
    @params[:term].tr("*", "%").downcase + "%"
  end

  def core_query
    Name.not_a_duplicate
        .full_name_like(prepared_search_term)
        .avoids_id(@params[:avoid_id].try("to_i") || -1)
        .joins(:name_status)
        .joins("left outer join instance on instance.name_id = name.id")
        .order_by_rank_and_full_name
        .limit(SEARCH_LIMIT)
  end

  def rank_query
    @qry.family_name
  end

  def instance_phrase(count)
    ActionController::Base.helpers.pluralize(count, "instance")
  end

  def query
    @qry = core_query
    @qry = rank_query
    @qry = @qry.select_fields_for_family_typeahead
               .group(GROUP_BY)
               .collect do |n|
      { value: "#{n.full_name} | #{n.name_rank_name} | " \
               "#{n.name_status_name} | " \
               "#{instance_phrase(n.instance_count)} ",
        id: n.id }
    end
  end
end
