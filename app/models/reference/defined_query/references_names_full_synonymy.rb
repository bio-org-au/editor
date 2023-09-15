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
#   A defined query is one that the Search class knows about and may
#   instantiate.
class Reference::DefinedQuery::ReferencesNamesFullSynonymy
  attr_reader :results,
              :limited,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :count,
              :show_csv,
              :total

  TAG = "Reference::DefinedQuery::ReferencesNamesFullSynonymy"
  def initialize(parsed_request)
    @parsed_request = parsed_request
    run_query
  end

  def debug(s)
    Rails.logger.debug("#{TAG}: #{s}")
  end

  def run_query
    @show_csv = false
    if @parsed_request.count
      count_query
    else
      list_query
      @count = @results.size
    end
    @total = @relation = nil
    @common_and_cultivar_included = @ref_query.common_and_cultivar_included
    @has_relation = false
  end

  def ref_query_for_count
    force_list = true
    @limited = false
    @ref_query = Search::Reference::DefinedQuery.new(@parsed_request, force_list)
  end

  def count_query
    @count = 0
    ref_query_for_count
    @ref_query.results.each do |ref|
      @count += 1
      ref.instances.each do |instance|
        @count += 1
        @count += Instance::AsArray::ForName.new(instance.name).results.size if instance.name.present?
      end
    end
    @results = []
  end

  def list_query
    @ref_query = Search::Reference::DefinedQuery.new(@parsed_request)
    @results = []
    @limited = false
    @ref_query.results.each do |ref|
      ref_list(ref)
      if @results.size >= @parsed_request.limit
        @limited = true
        break
      end
    end
  end

  def ref_list(ref)
    @results.push(ref)
    ref.instances.each do |instance|
      @results.push(instance.name)
      @results.concat(Instance::AsArray::ForName.new(instance.name).results)
      if results.size >= @parsed_request.limit
        @limited = true
        break
      end
    end
  end

  def csv?
    @show_csv
  end
end
