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
class Search::Empty
  attr_reader :empty,
              :error,
              :error_message,
              :executed_query,
              :more_allowed,
              :parsed_request

  def initialize(params)
    Rails.logger.debug("Search::Empty start (setting up an empty search)")
    Rails.logger.debug(("=" * 40).to_s)
    @parsed_request = Search::EmptyParsedRequest.new(params)
    @common_and_cultivar_included = true
    @count = false
    @empty = true
    @error = !params[:error_message].blank?
    @error_message = params[:error_message]
    @tree = false
    @limited = false
    @query_string = params[:query]
    @more_allowed = false
    @executed_query = Search::EmptyExecutedQuery.new(params)
  end

  def to_history
    ""
  end
end
