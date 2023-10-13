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
class Audit::DefinedQuery::Base
  attr_reader :count,
              :common_and_cultivar_included,
              :has_relation,
              :limited,
              :relation,
              :results,
              :show_csv,
              :total,
              :do_count_totals

  def initialize(parsed_request)
    run_query(parsed_request)
    @do_count_totals = true
  end

  def run_query(parsed_request)
    if parsed_request.count
      run_count_query(parsed_request)
    else
      run_list_query(parsed_request)
    end
  end

  def run_count_query(parsed_request)
    query = Audit::DefinedQuery::CountQuery.new(parsed_request)
    @has_relation = false
    @relation = nil
    @results = query.results
    @limited = query.limited
    @common_and_cultivar_included = query.common_and_cultivar_included
    @count = @results.size
    @results = []
    @show_csv = false
    @total = nil
  end

  def run_list_query(parsed_request)
    query = Audit::DefinedQuery::ListQuery.new(parsed_request)
    @has_relation = false
    @relation = nil
    @results = query.results
    @limited = query.limited
    @common_and_cultivar_included = query.common_and_cultivar_included
    @count = @results.size
    @show_csv = false
    @total = nil
  end

  def csv?
    @show_csv
  end

  def debug(s)
    tag = "Audit::DefinedQuery::Base #{s}"
    Rails.logger.debug("#{tag}: #{s}")
  end
end
