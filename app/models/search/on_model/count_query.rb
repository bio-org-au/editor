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
class Search::OnModel::CountQuery
  attr_reader :sql, :info_for_display, :common_and_cultivar_included

  def initialize(parsed_request)
    @parsed_request = parsed_request
    @view_mode = parsed_request.params[:view_mode]
    prepare_query
    @info_for_display = "nothing yet from count query"
  end

  def prepare_query
    Rails.logger.debug("Search::OnModel::CountQuery#prepare_query")

    @model_class = @parsed_request.target_model.constantize
    if @parsed_request.target_table.match(/loader.name/) && @view_mode == 'review_view'
      prepared_query = @model_class.where("record_type != 'in-batch-compiler-note'")
    else
      prepared_query = @model_class.where("1=1")
    end

    where_clauses = Search::OnModel::WhereClauses.new(@parsed_request,
                                                      prepared_query)
    prepared_query = where_clauses.sql
    @sql = prepared_query
  end
end
