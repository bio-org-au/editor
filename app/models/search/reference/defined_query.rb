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
class Search::Reference::DefinedQuery
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
              :full_count_known

  def initialize(parsed_request, force_list_query = false)
    @parsed_request = parsed_request
    @force_list_query = force_list_query
    run_query
  end

  def run_query
    @has_relation = true
    @rejected_pairings = []
    if @parsed_request.count && !@force_list_query
      run_count_query
    else
      run_list_query
    end
  end

  def run_count_query
    count_query = Search::Reference::DefinedQuery::Count.new(@parsed_request)
    @relation = count_query.sql
    @total = @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
    @show_csv = false
    @total = nil
  end

  def run_list_query
    list_query = Search::Reference::DefinedQuery::List.new(@parsed_request)
    @relation = list_query.sql
    @references = relation.all
    @info_for_display = list_query.info_for_display
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    consider_instances
    @count = @results.size
    @show_csv = false
    calculate_total
    @limited = (@full_count_known && @total > @relation.size) || !@full_count_known
  end

  def consider_instances
    if @parsed_request.show_instances
      show_instances
    else
      @results = @references
    end
  end

  def instances_sort_key
    @parsed_request.order_instances_by_page ? "page" : "name"
  end

  def show_instances
    @results = []
    @references.each do |ref|
      @results << ref
      instances_query = Instance::AsArray::ForReference
                        .new(ref,
                             instances_sort_key,
                             @parsed_request.limit,
                             @parsed_request.instance_offset)
      instances_query.results.each { |i| @results << i }
    end
  end

  def debug(s)
    Rails.logger.debug("Search::Reference::DefinedQuery: #{s}")
  end

  def csv?
    @show_csv
  end

  def calculate_total
    @total = if @parsed_request.show_instances
               @limited = true
               @full_count_known = false
               @results.size
             else
               @full_count_known = true
               @relation.except(:offset, :limit, :order).count
             end
  end
end
