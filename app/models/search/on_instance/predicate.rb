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
class Search::OnInstance::Predicate
  attr_reader :canon_field,
              :canon_value,
              :trailing_wildcard,
              :leading_wildcard,
              :multiple_values,
              :predicate,
              :value_frequency,
              :processed_value,
              :tokenize,
              :field,
              :value,
              :has_scope,
              :scope_,
              :order,
              :join_name

  def initialize(field, value)
    debug("Start")
    @field = field
    @value = value
    @canon_field = build_canon_field(field)
    @rule = Search::OnInstance::FieldRule.resolve(@canon_field)
    @is_null = value.blank?
    apply_rule
    @canon_value = build_canon_value
    apply_scope
    @order = @rule[:order] || nil
    process_value
  end

  def debug(s)
    Rails.logger.debug("Search::OnInstance::Predicate - #{s}")
  end

  def inspect
    "Search::OnInstance::Predicate: canon_field: #{@canon_field}"
  end

  def apply_rule
    @scope_ = @rule[:scope_] || ""
    @trailing_wildcard = @rule[:trailing_wildcard] || false
    @leading_wildcard = @rule[:leading_wildcard] || false
    apply_rule_overflow
  end

  def apply_rule_overflow
    @multiple_values = @rule[:multiple_values] || false
    @predicate = build_predicate
    # TODO: build this into the @rule
    # @value = @value.downcase unless @canon_field =~ /-match/i
    @value = @value.downcase unless @rule[:case_sensitive]
    @tokenize = @rule[:tokenize] || false
    @join_name = @rule[:join] == :name
  end

  def apply_scope
    @has_scope = @scope_.present?
    @value_frequency = if @has_scope
                         1
                       else
                         @predicate.count("?")
                       end
  end

  def process_value
    @processed_value = @canon_value
    @processed_value = "%#{@processed_value}" if @leading_wildcard
    @processed_value = "#{@processed_value}%" if @trailing_wildcard
  end

  def build_predicate
    if @multiple_values && @value.split(/,/).size > 1
      @rule[:multiple_values_where_clause]
    else
      build_scalar_predicate
    end
  end

  def build_scalar_predicate
    if @is_null
      build_is_null_predicate
    else
      @rule[:where_clause]
    end
  end

  def build_is_null_predicate
    if @rule[:not_exists_clause].present?
      @rule[:not_exists_clause]
    else
      @rule[:where_clause].gsub(/= \?/, "is null")
                          .gsub(/like lower\(\?\)/, "is null")
                          .gsub(/like lower\(f_unaccent\(\?\)\)/, "is null")
    end
  end

  def build_canon_value
    if @multiple_values && @value.split(/,/).size > 1
      @value.split(",").collect(&:strip)
    else
      convert_asterisk_to_percent
    end
  end

  def convert_asterisk_to_percent
    case @rule[:convert_asterisk_to_percent]
    when nil
      @value.tr("*", "%")
    when true
      @value.tr("*", "%")
    else
      @value
    end
  end

  def build_canon_field(field)
    if Search::OnInstance::FieldRule::RULES.key?(field)
      field
    elsif Search::OnInstance::FieldRule::RULES.key?(
      # redundant?
      Search::OnInstance::FieldAbbrev::ABBREVS[field]
    )
      Search::OnInstance::FieldAbbrev::ABBREVS[field]
    elsif field_matches_a_note_key?(field)
      field
    else
      raise "Cannot search instances for: #{field}. You may need to try another
      search term or target."
    end
  end

  def field_matches_a_note_key?(field)
    InstanceNoteKey.string_has_embedded_note_key?(field)
  end
end
