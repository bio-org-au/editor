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
# Search on Orchids
class Search::OnOrchids::Base
  attr_reader :results,
              :limited,
              :info_for_display,
              :rejected_pairings,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :id,
              :count,
              :show_csv,
              :total,
              :do_count_totals

  def initialize(parsed_request)
    run_query(parsed_request)
    @do_count_totals = true
  end

  def run_query(parsed_request)
    @has_relation = true
    @show_csv = false
    @rejected_pairings = []
    if parsed_request.count
      run_count_query(parsed_request)
    else
      run_list_query(parsed_request)
    end
  end

  def run_count_query(parsed_request)
    count_query = Search::OnOrchids::CountQuery.new(parsed_request)
    @relation = count_query.sql
    @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
    @total = nil
  end

  def run_list_query(parsed_request)
    list_query = Search::OnOrchids::ListQuery.new(parsed_request)
    @relation = list_query.sql
    @results = relation.all
    @limited = list_query.limited
    @info_for_display = list_query.info_for_display
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    @count = @results.size
    calculate_total
  end

  def debug(s)
    Rails.logger.debug("Search::OnOrchids::Base: #{s}")
  end

  def csv?
    @show_csv
  end

  def calculate_total
    @total = @relation.except(:offset, :limit, :order).count
  end
end
