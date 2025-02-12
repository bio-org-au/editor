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
class Search::OnInstance::Base
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
    @rejected_pairings = []
    if parsed_request.count
      run_count_query(parsed_request)
    else
      run_list_query(parsed_request)
    end
  end

  def run_count_query(parsed_request)
    debug("#run_count_query")
    count_query = Search::OnInstance::CountQuery.new(parsed_request)
    @relation = count_query.sql
    @total = @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
    @show_csv = false
    @total = nil
  end

  def run_list_query(parsed_request)
    debug("#run_list_query")
    list_query = Search::OnInstance::ListQuery.new(parsed_request)
    @relation = list_query.sql
    @results = relation.all
    @results = include_profile_items(@results) if parsed_request.show_profiles
    @limited = list_query.limited
    @info_for_display = list_query.info_for_display
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    @count = @results.size
    @show_csv = @results.size.positive?
    calculate_total
  end

  def debug(s)
    Rails.logger.debug("Search::OnInstance::Base: #{s}")
  end

  def csv?
    @show_csv
  end

  def calculate_total
    @total = @relation.except(:offset, :limit, :order).count
  end

  def include_profile_items(instances)
    results = []
    instances.each do |instance|
      results << instance
      results << instance.profile_items.where(profile_object_rdf_id: "text")
      results.flatten!
    end

    results
  end
end
