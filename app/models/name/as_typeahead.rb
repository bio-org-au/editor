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
class Name::AsTypeahead < Name
  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.cultivar_parent_suggestions(term, avoid_id, rank_id = -1)
    logger.debug("cultivar_parent_suggestions term: #{term}
                 avoiding: #{avoid_id} for rank: #{rank_id}")
    if term.blank?
      results = []
    else
      query = Name.not_a_duplicate
                  .full_name_like(term)
                  .avoids_id(avoid_id.try("to_i") || -1)
                  .joins(:name_rank)
                  .joins(:name_status)
                  .name_rank_not_deprecated
                  .name_rank_not_infra
                  .name_rank_not_na
                  .name_rank_not_unknown
                  .name_rank_genus_and_below
                  .select_fields_for_typeahead
                  .order_by_full_name
                  .limit(SEARCH_LIMIT)
      query = if rank_id != "undefined" && NameRank.id_is_unranked?(rank_id.to_i)
                query.ranks_for_unranked_assumes_join
              else
                query.name_rank_not_unranked
              end
      query = query.collect do |n|
        { value: "#{n.full_name} | #{n.name_rank_name} ", id: n.id }
      end
      results = query
    end
    results
  end

  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.hybrid_parent_suggestions(term, avoid_id, rank_id = -1)
    logger.debug("hybrid_parent_suggestions term: #{term}
                 avoiding: #{avoid_id} for rank: #{rank_id}")
    term_for_query = term.strip
    if term_for_query.blank?
      results = []
    else
      query = Name.not_a_duplicate
                  .full_name_like(term_for_query)
                  .avoids_id(avoid_id.try("to_i") || -1)
                  .joins(:name_rank)
                  .joins(:name_status)
                  .name_rank_not_deprecated
                  .name_rank_not_infra
                  .name_rank_not_na
                  .name_rank_not_unknown
                  .name_rank_species_and_below
                  .select_fields_for_typeahead
                  .order_by_full_name
                  .limit(SEARCH_LIMIT)
      query = if rank_id != "undefined" && NameRank.id_is_unranked?(rank_id.to_i)
                query.ranks_for_unranked_assumes_join
              else
                query.name_rank_not_unranked
              end
      query = query.collect do |n|
        { value: "#{n.full_name} | #{n.name_rank_name}#{n.pipe_for_name_status}" \
               "#{n.name_status_name} ", id: n.id }
      end
      results = query
    end
    results
  end

  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.duplicate_suggestions(term, avoid_id)
    logger.debug("duplicate_suggestions for term: #{term};
                 avoiding: #{avoid_id}")
    if term.blank?
      results = []
    else
      query = Name.not_a_duplicate
                  .full_name_like(term)
                  .avoids_id(avoid_id.to_i)
                  .joins(:name_rank)
                  .joins(:name_status)
                  .select_fields_for_typeahead
                  .limit(SEARCH_LIMIT)
                  .order_by_full_name
      results = query.collect do |n|
        { value: "#{n.full_name} | #{n.name_status_name}", id: n.id }
      end
    end
    results
  end
end
