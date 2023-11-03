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
class Instance::DefinedQuery::IsCitedBy
  attr_reader :common_and_cultivar_included,
              :count,
              :has_relation,
              :limited,
              :relation,
              :results,
              :show_csv,
              :total,
              :do_count_totals

  def initialize(parsed_request)
    @do_count_totals = true
    run_query(parsed_request)
  end

  def debug(s)
    tag = "Instance::DefinedQuery::IsCitedBy"
    Rails.logger.debug("#{tag}: #{s}")
  end

  def run_query(parsed_request)
    @show_csv = false
    @total = nil
    if parsed_request.count
      debug("run_query counting")
      query = Search::OnReference::ListQuery.new(parsed_request)
      @relation = query.sql # TODO: work out how to provide the relation and sql
      results = relation.all
      limited = query.limited

      debug(results.size)
      tally = results.size
      results.each do |ref|
        debug(ref.id)
        tally += ref.instances.size
      end
      debug("tally: #{tally}")

      @limited = limited
      @common_and_cultivar_included = query.common_and_cultivar_included
      @count = tally
    else
      debug("query listing")
      instance = Instance.find_by(id: parsed_request.where_arguments)
      @results = instance.present? ? instance.reverse_of_this_is_cited_by : []
      @limited = false; # name_query.limited
      @common_and_cultivar_included = true
      @count = @results.size
      @has_relation = false
      @relation = nil
    end
  end

  def csv?
    @show_csv
  end
end
