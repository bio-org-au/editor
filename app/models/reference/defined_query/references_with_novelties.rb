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
#   A defined query is one that the Search class knows about and may
#   instantiate.
class Reference::DefinedQuery::ReferencesWithNovelties
  attr_reader :results,
              :limited,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :count,
              :show_csv,
              :total,
              :do_count_totals

  def initialize(parsed_request)
    run_query(parsed_request)
    @do_count_totals = true
  end

  def debug(s)
    tag = "Reference::DefinedQuery::ReferencesWithNovelties"
    Rails.logger.debug("#{tag}: #{s}")
  end

  def run_query(parsed_request)
    @show_csv = false
    if parsed_request.count
      debug("run_query counting")
      debug(parsed_request.inspect)
      query = Search::Reference::DefinedQuery.new(parsed_requestt)
      results = []
      query.results.each do |ref|
        results.concat(list_novelties(ref, 100_000))
      end
      @count = results.size
      @limited = false
      @common_and_cultivar_included = query.common_and_cultivar_included
    else
      debug("run_query listing with limit: #{parsed_request.limit}")
      query = Search::Reference::DefinedQuery.new(parsed_request)
      debug(query.results.size)
      results = []
      @limited = false
      query.results.each do |ref|
        results.concat(list_novelties(ref, parsed_request.limit))
        if results.size >= parsed_request.limit
          @limited = true
          break
        end
      end
      debug("results.size: #{results.size}")
      @common_and_cultivar_included = query.common_and_cultivar_included
      @results = results
      @count = results.size
      @has_relation = false
      @relation = nil
    end
    @total = nil
  end

  def list_novelties(reference, limit = 100, order_by = "name")
    debug("list_novelties: reference.id: #{reference.id}; limit: #{limit}; order by: #{order_by}")
    results = []
    reference.display_as_part_of_concept
    count = 1
    query = reference.instances.joins(:name).includes(name: :name_status).joins(:instance_type).where(instance_type: { primary_instance: true })
    query = order_by == "page" ? query.ordered_by_page : query.ordered_by_name
    novelties_count = 0
    query.each do |instance|
      novelties_count += 1
      instance.display_within_reference
      count += 1
      if count > limit
        @limited = true
        break
      end
      results.push(instance)
    end
    results.unshift(reference) if novelties_count.positive?
    results
  end

  def csv?
    @show_csv
  end
end
