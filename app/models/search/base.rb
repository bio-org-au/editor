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
# Core class for queries.
class Search::Base
  attr_reader :empty,
              :error,
              :error_message,
              :executed_query,
              :more_allowed,
              :parsed_request,
              :specific_search

  DEFAULT_PAGE_SIZE = 100
  PAGE_INCREMENT_SIZE = 500
  MAX_PAGE_SIZE = 10_000

  def initialize(params)
    @params = params
    @params[:canonical_query_target] = @params[:query_target]
    @params[:canonical_query_target] = @params[:canonical_query_target].downcase.gsub(', ','_').gsub(' ','_')
    set_defaults
    run_query
  end

  def run_query
    @parsed_request = Search::ParsedRequest.new(@params)
    if @parsed_request.defined_query
      run_defined_query
    else
      run_plain_query
    end
  end
 
  def debug(s)
    Rails.logger.debug("Search::Base #{s}")
  end

  def set_defaults
    @empty = false
    @error = false
    @error_message = ""
  end

  def to_history
    { "query_string" => @params[:query_string],
      "query_target" => @parsed_request.query_target,
      "canonical_query_target" => @parsed_request.canonical_query_target,
      "result_size" => @executed_query.count,
      "time_stamp" => Time.now,
      "error" => false }
  end

  def page_increment_size
    PAGE_INCREMENT_SIZE
  end

  def run_plain_query
    @count_allowed = true
    @executed_query =
      case @parsed_request.target_table
      when /any/ then raise "cannot run an 'any' search yet"
      when /^name/ then Search::OnName::Base.new(@parsed_request)
      when /author/ then Search::OnModel::Base.new(@parsed_request)
      when /instance/ then Search::OnInstance::Base.new(@parsed_request)
      when /reference/ then Search::OnReference::Base.new(@parsed_request)
      when /orchids/ then Search::OnOrchids::Base.new(@parsed_request)
      when /orchid.processing.log/ then Search::OnOrchidProcessingLogs::Base.new(@parsed_request)
      when /loader.batch/ then Search::OnModel::Base.new(@parsed_request)
      when /loader.name/ then Search::OnModel::Base.new(@parsed_request)
      when /^batch.review$/ then Search::OnModel::Base.new(@parsed_request)
      when /^batch.reviewer$/ then Search::OnModel::Base.new(@parsed_request)
      when /^batch.review.period$/ then Search::OnModel::Base.new(@parsed_request)
      when /^users$/ then Search::OnModel::Base.new(@parsed_request)
      when /^org$/ then Search::OnModel::Base.new(@parsed_request)
      else raise 'unknown target table'
      end
  end

  def run_defined_query
    @count_allowed = false
    if @parsed_request.defined_query_arg.blank? &&
       @parsed_request.where_arguments.blank?
      raise "Defined queries need an argument."
    else
      run_specific_defined_query
    end
  end

  def run_specific_defined_query
    @executed_query =
      case @parsed_request.defined_query
      when /references.name.full.synonymy/
        Reference::DefinedQuery::ReferencesNamesFullSynonymy
      .new(@parsed_request)
      when /\Ainstance.is.cited\z/
        Instance::DefinedQuery::IsCited.new(@parsed_request)
      when /\Ainstance.is.cited.by\z/
        Instance::DefinedQuery::IsCitedBy.new(@parsed_request)
      when /\Aaudit\z/
        Audit::DefinedQuery::Base.new(@parsed_request)
      when /\Areferences.with.novelties\z/
        Reference::DefinedQuery::ReferencesWithNovelties.new(@parsed_request)
      when /\Areferences.accepted.names.for.id\z/i
        Reference::DefinedQuery::ReferencesAcceptedNamesForId
      .new(@parsed_request)
      when /\Areferences.shared.names\z/i
        Reference::DefinedQuery::ReferencesSharedNames.new(@parsed_request)
      else
        Rails.logger.error("Search::Base failed to run defined query: "\
                           "#{@parsed_request.defined_query}")
        raise "No such defined query: #{@parsed_request.defined_query}"
      end
  end
end
