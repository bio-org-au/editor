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
#
# Build a loader_name bulk search query based on a search string
class Loader::Name::BulkSearch
  attr_reader :search

  SPLITTER = ';;;;;;'
  DEFAULT_DIRECTIVE = 'simple-name:'

  def initialize(search_s, batch_id, accepted_or_excluded_only = false)
    @batch_id = batch_id
    @search_s = search_s
    @accepted_or_excluded_only = accepted_or_excluded_only
    @search_a = search_s_to_a
    @search = bulk_processing_search
  end

  def search_s_to_a
    add_default_directive
    array = @search_s.gsub(/([a-z-]+:)/, SPLITTER + '\1')
                     .split(SPLITTER)
                     .compact_blank
    remove_empty_default_directive(array)
  end

  def add_default_directive
    @search_s = "#{DEFAULT_DIRECTIVE}   #{@search_s}"
  end

  def remove_empty_default_directive(array)
    array.delete_if{|e| e.match(/\A#{DEFAULT_DIRECTIVE} *\z/)}
    array
  end

  def bulk_processing_search
    @core_query = Loader::Name.joins(:loader_batch)
                              .where(loader_batch: { id: @batch_id })
    @core_query = add_simple_name_clause unless @search_a.grep(/\b#{DEFAULT_DIRECTIVE}/).blank?
    @core_query = add_family_clause unless @search_a.grep(/\bfamily:/).blank?
    @core_query = add_acc_clause unless @search_a.grep(/\bacc:/).blank?
    @core_query = add_exc_clause unless @search_a.grep(/\bexc:/).blank?
    @core_query = must_be_accepted_or_excluded if @accepted_or_excluded_only
    @core_query
  end

  def add_simple_name_clause
    sn_directive = @search_a.select {|i| i[/simple-name:/]}.first
    sn_string = sn_directive.sub(/\Asimple-name: */i, "").strip
    @core_query.simple_name_search(sn_string)
  end

  def add_family_clause
    family_directive = @search_a.select {|i| i[/family:/]}.first
    family_string = family_directive.sub(/\Afamily: */i, "").strip
    @core_query.family_string_search(family_string)
  end

  def add_acc_clause
    acc_directive = @search_a.select {|i| i[/acc:/]}.first
    acc_string = acc_directive.sub(/\Aacc: */i, "").strip
    @core_query.acc_string_search(acc_string)
  end

  def add_exc_clause
    exc_directive = @search_a.select {|i| i[/exc:/]}.first
    exc_string = exc_directive.sub(/\Aexc: */i, "").strip
    @core_query.exc_string_search(exc_string)
  end

  def must_be_accepted_or_excluded
    @core_query.accepted_or_excluded_search
  end
end
