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
class Search::OnModel::ListQuery
  attr_reader :sql, :limited, :info_for_display, :common_and_cultivar_included, :do_count_totals

  def initialize(parsed_request)
    @parsed_request = parsed_request
    @view_mode = parsed_request.params[:view_mode]
    prepare_query
    @limited = true
    @info_for_display = ""
  end

  def prepare_query
    if @parsed_request.target_model.nil?
      raise "Target '#{@parsed_request.target_table}' is not registered with parsed request."
    end

    @model_class = @parsed_request.target_model.constantize
    if @parsed_request.target_table.match(/loader.name/) && @view_mode == 'review_view'
      prepared_query = @model_class.where("record_type != 'in-batch-compiler-note'")
    else
      prepared_query = @model_class.where("1=1")
    end
    where_clauses = Search::OnModel::WhereClauses.new(@parsed_request, prepared_query)
    @do_count_totals = where_clauses.do_count_totals
    prepared_query = where_clauses.sql
    prepared_query = prepared_query.limit(@parsed_request.limit) if @parsed_request.limited
    prepared_query = prepared_query.offset(@parsed_request.offset) if @parsed_request.offsetted
    prepared_query = prepared_query.order((Name.sanitize_sql_for_order("#{@parsed_request.default_order_column}")))
    @sql = prepared_query
  end

  def trim_results(results)
    results
  end

  # Seems redundant
  def xtrim_results(results)
    if @parsed_request.trim_results? && results.size > @parsed_request.limit
      @model_class.trim_results(results)
    else
      results
    end
  end
end
