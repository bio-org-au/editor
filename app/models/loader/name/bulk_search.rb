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

  SPLITTER = ";;;;;;"
  DEFAULT_DIRECTIVE = "simple-name:"

  def initialize(search_s, batch_id, accepted_or_excluded_only = false)
    @batch_id = batch_id
    @search_s = search_s
    @accepted_or_excluded_only = accepted_or_excluded_only
    @search_a = search_s_to_a
    bulk_processing_search
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
    array.delete_if { |e| e.match(/\A#{DEFAULT_DIRECTIVE} *\z/) }
    array
  end

  def bulk_processing_search
    @search = Loader::Name.joins(:loader_batch)
                          .where(loader_batch: { id: @batch_id })
                          .order(' sort_key, seq, id')
    consume_directives
    raise "Unknown search #{'directive'.pluralize(@search_a.size)}: #{@search_a.join(' ')}" unless @search_a.empty?
  end

  def consume_directives
    @search = add_simple_name_clause unless @search_a.grep(/\b#{DEFAULT_DIRECTIVE}/).blank?
    @search = add_family_clause unless @search_a.grep(/\bfamily:/).blank?
    @search = add_acc_clause unless @search_a.grep(/\bacc:/).blank?
    @search = add_exc_clause unless @search_a.grep(/\bexc:/).blank?
    @search = must_be_accepted_or_excluded if @accepted_or_excluded_only
  end

  def add_simple_name_clause
    sn_directive = @search_a.select { |i| i[/simple-name:/] }.first
    @search_a.reject! { |i| i[/simple-name:/]}
    sn_string = sn_directive.sub(/\Asimple-name: */i, "").strip
    @search.simple_name_search(sn_string)
  end

  # Family clause can be like this
  #
  #     family: one-family-name*
  # 
  # which can have wildcard because converted to SQL like
  #
  #     family like 'one-family-name%'
  #
  # But a family clause ike this -
  #
  #     family: one-family-name, another-family-name, yet-another
  #
  # cannot have wildcards because they get converted to SQL like this
  #
  #     family in ('one-family-name', 'another-family-name', 'yet-another')
  #
  def add_family_clause
    family_directive = @search_a.select { |i| i[/family:/] }.first
    @search_a.reject! { |i| i[/family:/]}
    family_string = family_directive.sub(/\Afamily: */i, "").strip
    family_a = family_string.split(/ *, */)
    if family_a.length < 2
      @search.family_string_search(family_string)
    else
      search_family_in_list_of_families(family_a)
    end
  end

  # Convert list of families to SQL:family in ('a','b','c')
  def search_family_in_list_of_families(family_a)
    s = "lower(family) in ("
    family_a.size.times do
      s += '?,'
    end
    s.chop!
    s += ')'
    @search.where([s] + family_a.map(&:downcase))
  end

  def add_acc_clause
    acc_directive = @search_a.select { |i| i[/acc:/] }.first
    @search_a.reject! { |i| i[/acc:/]}
    acc_string = acc_directive.sub(/\Aacc: */i, "").strip
    @search.acc_string_search(acc_string)
  end

  def add_exc_clause
    exc_directive = @search_a.select { |i| i[/exc:/] }.first
    @search_a.reject! { |i| i[/exc:/]}
    exc_string = exc_directive.sub(/\Aexc: */i, "").strip
    @search.exc_string_search(exc_string)
  end

  def must_be_accepted_or_excluded
    @search.accepted_or_excluded_search
  end
end
