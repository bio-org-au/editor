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
# Build where clauses for model searches.
class Search::OnModel::WhereClauses
  attr_reader :sql

  def initialize(parsed_request, incoming_sql)
    @parsed_request = parsed_request
    @sql = incoming_sql
    build_sql
  end

  def debug(s)
    Rails.logger.debug("Search::OnModel::WhereClause - #{s}")
  end

  def build_sql
    args = @parsed_request.where_arguments.downcase
    @common_and_cultivar_included = @parsed_request.common_and_cultivar
    @sql = @sql.for_id(@parsed_request.id) if @parsed_request.id
    apply_args_to_sql(args)
    apply_args_to_sql(@parsed_request.default_query_scope) if @parsed_request.apply_default_query_scope == true
  end

  def apply_args_to_sql(args)
    debug("args: #{args.inspect}")
    x = 0
    until args.blank?
      field, value, args = Search::NextCriterion.new(args).get
      add_clause(field, value)
      x += 1
      raise "endless loop #{x}" if x > 50
    end
  end

  def add_clause(field, value)
    debug("add_clause for field: #{field}; value: #{value}")
    if field.blank? && value.blank?
      @sql
    else
      field_or_default = field.blank? ? @parsed_request.default_query_directive : field
      debug("field_or_default: #{field_or_default}")
      rule = Search::OnModel::Predicate.new(@parsed_request,
                                            field_or_default,
                                            value)
      apply_rule(rule)
      apply_order(rule)
    end
  end

  def apply_rule(rule)
    if rule.tokenize
      tokenize(rule)
    elsif rule.has_scope
      # http://stackoverflow.com/questions/14286207/
      # how-to-remove-ranking-of-query-results
      @sql = @sql.send(rule.scope_, rule.value).reorder(@parsed_request.default_order_column)
    else
      apply_predicate(rule, rule.value_frequency)
    end
  end

  def apply_predicate(rule, frequency)
    debug("apply predicate")
    case frequency
    when 0 then @sql = @sql.where(rule.predicate)
    when 1 then @sql = @sql.where(rule.predicate, rule.processed_value)
    when 2 then supply_token_twice(rule, rule.processed_value)
    when 3 then supply_token_thrice(rule, rule.processed_value)
    when 4 then supply_token_4_times(rule, rule.processed_value)
    when 5 then supply_token_5_times(rule, rule.processed_value)
    when 6 then supply_token_6_times(rule, rule.processed_value)
    else
      raise "Where clause value frequency: #{frequency}, is too high."
    end
  end

  def supply_token_twice(rule, token)
    @sql = @sql.where(rule.predicate,
                      token,
                      token)
  end

  def supply_token_thrice(rule, token)
    @sql = @sql.where(rule.predicate,
                      token,
                      token,
                      token)
  end

  def supply_token_4_times(rule, token)
    @sql = @sql.where(rule.predicate,
                      token,
                      token,
                      token,
                      token)
  end

  def supply_token_5_times(rule, token)
    @sql = @sql.where(rule.predicate,
                      token,
                      token,
                      token,
                      token,
                      token)
  end

  def supply_token_6_times(rule, token)
    @sql = @sql.where(rule.predicate,
                      token,
                      token,
                      token,
                      token,
                      token,
                      token)
  end

  def apply_predicate_for_token(rule, token)
    debug("apply predicate for token: #{token}")
    case rule.value_frequency
    when 0 then @sql = @sql.where(rule.predicate)
    when 1 then @sql = @sql.where(rule.predicate, token)
    when 2 then supply_token_twice(rule, token)
    when 3 then supply_token_thrice(rule, token)
    when 4 then supply_token_4_times(rule, token)
    when 5 then supply_token_5_times(rule, token)
    when 6 then supply_token_6_times(rule, token)
    else
      raise "Where-clause value frequency (#{rule.value_frequency}) too high."
    end
  end

  def tokenize(rule)
    debug("tokenize: rule.predicate: #{rule.predicate}")
    debug("tokenize: rule.value: #{rule.value}")
    rule.value.tr("*", "%").gsub(/%+/, " ").split.each do |term|
      @sql = apply_predicate_for_token(rule, "%#{term}%")
    end
  end

  def apply_order(rule)
    @sql = if rule.order
             @sql.order(Arel.sql(rule.order))
           else
             @sql.order(@parsed_request.default_order_column)
           end
  end
end
