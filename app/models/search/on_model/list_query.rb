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
  attr_reader :sql, :limited, :info_for_display, :common_and_cultivar_included

  def initialize(parsed_request)
    @parsed_request = parsed_request
    prepare_query
    @limited = true
    @info_for_display = ""
  end

  def prepare_query
    Rails.logger.debug("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    Rails.logger.debug("===========================================================================================")
    Rails.logger.debug("Search::OnModel::ListQuery#prepare_query on target: #{@parsed_request.target_table}")
    Rails.logger.debug("Search::OnModel::ListQuery#prepare_query target model: #{@parsed_request.target_model}")
    Rails.logger.debug("===========================================================================================")
    model_class = @parsed_request.target_model.constantize
    prepared_query = model_class.where("1=1")
    Rails.logger.debug("Search::OnModel::ListQuery#prepare_query sql: #{prepared_query.to_sql}")
    Rails.logger.debug("===========================================================================================")
    where_clauses = Search::OnModel::WhereClauses.new(@parsed_request, prepared_query)
    prepared_query = where_clauses.sql
    prepared_query = prepared_query.limit(@parsed_request.limit) if @parsed_request.limited
    prepared_query = prepared_query.order(@parsed_request.default_order_column)
    Rails.logger.debug("Search::OnModel::ListQuery#prepare_query sql: #{prepared_query.to_sql}")
    Rails.logger.debug("===========================================================================================")
    @sql = prepared_query
  end
end
