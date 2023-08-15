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
class Search::EmptyParsedRequest
  attr_reader :empty,
              :canonical_query_string,
              :common_and_cultivar,
              :count,
              :defined_query,
              :defined_query_arg,
              :id,
              :limit,
              :limited,
              :list,
              :order,
              :params,
              :query_string,
              :target_table,
              :where_arguments,
              :query_target,
              :target_button_text,
              :show_instances,
              :print,
              :display

  def initialize(params)
    @params = params
    @empty = true
    @defined_query = false
    @target_button_text = params[:query_target] || "Names"
    @count = false
    @list = false
    @limited = false
    @common_and_cultivar = false
    @order = ""
    @query_string = params[:query_string]
    @print = false
    @display = !@print
  end
end
