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
class Name::AsTypeahead::ForParent
  attr_reader :suggestions,
              :params

  SEARCH_LIMIT = 50
  GROUP_BY = "name.id,name.full_name,name_rank.name,name_status.name," \
             "name_rank.sort_order, family_full_name"

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
        .lower_full_name_like_for_parent_typeahead(prepared_search_term)
        .avoids_id(@params[:avoid_id].try("to_i") || -1)
        .joins("left outer join name families_name on name.family_id = families_name.id")
        .joins(:name_status)
        .joins("left outer join instance on instance.name_id = name.id")
        .order_by_rank_and_full_name_for_parent_typeahead
        .limit(SEARCH_LIMIT)
  end

  def rank_query
    @qry = @qry.joins(:name_rank)
    rank = NameRank.find(@params[:rank_id])
    if rank.unranked?
      return @qry
    elsif rank.infrageneric? && !rank.genus?
      @qry = @qry.parent_ranks_for_infragenus
      @qry = @qry.from_a_higher_rank(@params[:rank_id])
      return @qry
    elsif rank.species?
      return species_are_always_restricted
    elsif rank.infraspecific?
      return infraspecies_are_always_restricted(rank)
    end

    if fully_restricted
      full_rank_restrictions(rank)
    else
      rank_must_be_higher(rank)
    end
    @qry
  end

  def fully_restricted
    ShardConfig.name_parent_rank_restriction?
  end

  def species_are_always_restricted
    @qry = @qry.parent_ranks_for_species
  end

  def infraspecies_are_always_restricted(_rank)
    @qry = @qry.parent_ranks_for_infraspecies
  end

  def full_rank_restrictions(rank)
    if rank.family?
      @qry = @qry.parent_ranks_for_family
    elsif rank.infrafamilial?
      @qry = @qry.parent_ranks_for_infrafamily
      @qry = @qry.from_a_higher_rank(@params[:rank_id])
    elsif rank.genus?
      @qry = @qry.parent_ranks_for_genus
    else
      @qry = @qry.from_a_higher_rank(@params[:rank_id])
      @qry = @qry.but_rank_not_too_high(@params[:rank_id])
    end
  end

  def rank_must_be_higher(rank)
    @qry = if rank.infrafamily?
             @qry.from_a_higher_rank(NameRank.find_by(name: "Genus"))
           else
             @qry.from_a_higher_rank(@params[:rank_id])
           end
  end

  def instance_phrase(count)
    ActionController::Base.helpers.pluralize(count, "instance")
  end

  def query
    @qry = core_query
    @qry = rank_query
    @qry = @qry.select_fields_for_parent_typeahead
               .group(GROUP_BY)
               .collect do |n|
      { value: "#{n.full_name} | #{n.name_rank_name} | " \
        "#{n.name_status_name}#{n.pipe_for_name_status}" \
               "#{instance_phrase(n.instance_count)} ",
        id: n.id,
        family_id: n.family_id,
        family_value: "#{n.family_full_name}" }
    end
  end
end
