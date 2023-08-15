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
class Search::OnName::WhereClauses
  attr_reader :sql

  DEFAULT_FIELD = "name:"

  def initialize(parsed_request, incoming_sql)
    @parsed_request = parsed_request
    @sql = incoming_sql
    build_sql
  end

  def debug(s)
    Rails.logger.debug("Search::OnName::WhereClause - #{s}")
  end

  def build_sql
    args = @parsed_request.where_arguments.downcase
    @common_and_cultivar_included =
      @parsed_request.include_common_and_cultivar_session
    @sql = @sql.for_id(@parsed_request.id) if @parsed_request.id
    apply_args_to_sql(args)
    @sql = @sql.not_common_or_cultivar unless @common_and_cultivar_included
  end

  def apply_args_to_sql(args)
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
      field_or_default = field.blank? ? DEFAULT_FIELD : field
      rule = Search::OnName::Predicate.new(field_or_default,
                                           value)
      apply_rule(rule)
      apply_common_and_cultivar(rule)
      apply_order(rule)
    end
  end

  def apply_rule(rule)
    if rule.tokenize
      apply_predicate_to_tokens(rule)
    elsif rule.has_scope
      # http://stackoverflow.com/questions/14286207/
      # how-to-remove-ranking-of-query-results
      @sql = @sql.send(rule.scope_, rule.value).reorder("full_name")
    else
      apply_predicate(rule)
    end
  end

  def apply_predicate(rule)
    case rule.value_frequency
    when 0 then @sql = @sql.where(rule.predicate)
    when 1 then @sql = @sql.where(rule.predicate, rule.processed_value)
    when 2 then supply_value_twice(rule)
    when 3 then supply_value_thrice(rule)
    when 4 then supply_value_four_times(rule)
    else
      raise "Token frequency (#{rule.value_frequency}) in name qry, too high."
    end
  end

  def supply_value_four_times(rule)
    @sql = @sql.where(rule.predicate,
                      rule.processed_value,
                      rule.processed_value,
                      rule.processed_value,
                      rule.processed_value)
  end

  def supply_value_thrice(rule)
    @sql = @sql.where(rule.predicate,
                      rule.processed_value,
                      rule.processed_value,
                      rule.processed_value)
  end

  def supply_value_twice(rule)
    @sql = @sql.where(rule.predicate,
                      rule.processed_value,
                      rule.processed_value)
  end

  def apply_predicate_to_tokens(rule)
    debug("apply_predicate_to_tokens: rule.predicate: #{rule.predicate}")
    debug("apply_predicate_to_tokens: rule.value: #{rule.value}")
    predicate = rule.predicate
    rule.value.tr("*", "%").gsub(/%+/, " ").split.each do |term|
      @sql = @sql.where(predicate, "%#{term}%")
    end
  end

  def apply_common_and_cultivar(rule)
    debug("apply_common_and_cultivar: #{rule.try('where_clause')}")
    return if @common_and_cultivar_included

    if rule.allow_common_and_cultivar
      @common_and_cultivar_included = true
      debug("now including common and cultivar!!!!!!")
    else
      debug("not including common and cultivar")
    end
  end

  def apply_order(rule)
    @sql = if rule.order
             @sql.order(Arel.sql(rule.order))
           else
             @sql.order("full_name")
           end
  end
end
