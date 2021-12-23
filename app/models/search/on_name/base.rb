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

# Core search class for Name search
#
# You can run this in the console, once you have a parsed request:
#
# search = Search::OnName::Base.new(parsed_request)
#
class Search::OnName::Base
  attr_reader :names,
              :limited,
              :info_for_display,
              :rejected_pairings,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :id,
              :count,
              :show_csv,
              :results,
              :summary,
              :total

  def initialize(parsed_request)
    @parsed_request = parsed_request
    run_query
  end

  def run_query
    @has_relation = true
    @rejected_pairings = []
    @show_csv = false
    if @parsed_request.count
      run_count_query
    else
      run_list_query
    end
  end

  def run_count_query
    count_query = Search::OnName::CountQuery.new(@parsed_request)
    @relation = count_query.sql
    @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @names = @results = []
    @total = nil
    @summary = "#{@names.size} names"
  end

  def run_list_query
    list_query = Search::OnName::ListQuery.new(@parsed_request)
    @relation = list_query.sql
    @names = relation.all
    @limited = list_query.limited
    @info_for_display = list_query.info_for_display
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    include_instances
    @count = @results.size
    calculate_total
    @summary = build_summary
  end

  def include_instances
    if @parsed_request.include_instances && @parsed_request.show_instances
      @results = Search::OnName::WithInstances.new(@names).names_with_instances
    else
      @results = @names.to_a
    end
  end

  def xshow_instances
    @results = []
    @names.each do |name|
      name.display_as_part_of_concept
      @results << name
      Instance::AsArray::ForName.new(name).results.each do |usage_rec|
        @results << usage_rec
      end
    end
  end

  def debug(s)
    Rails.logger.debug("Search::OnName::Base: #{s}")
  end

  def csv?
    @show_csv
  end

  def calculate_total
    @total = @relation.except(:offset, :limit, :order).count
  end

  def build_summary
    return "No names found" if @names.size.zero?
    return "1 name of #{@total}" if @names.size == 1
    "#{@names.size} names of #{@total}"
  end
end
