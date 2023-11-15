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
class Audit::DefinedQuery::WhereClause::Predicate
  attr_reader :sql

  def initialize(sql, field = nil, value = nil, record_type)
    debug("Start field: #{field}; value: #{value};")
    debug("record_type: #{record_type};")
    @sql = sql
    @record_type = record_type
    build_predicate(field, value)
    debug(@sql.to_sql)
  end

  def debug(s)
    Rails.logger.debug("Audit::DefinedQuery::WhereClause::Predicates #{s}")
  end

  def build_predicate(field, value)
    debug("#add_clause field: #{field}, value: #{value}")
    if field.blank? && value.blank?
      # do nothing @sql = sql
    elsif field.blank?
      # @sql = sql.created_or_updated_n_days_ago(value.to_i)
      @sql = sql.changed_in_the_last_n_days(value.to_i)
    else
      # we have a field
      canonical_field = canon_field(field)
      canonical_value = value.blank? ? "" : canon_value(value)
      if ALLOWS_MULTIPLE_VALUES.key?(canonical_field) &&
         canonical_value.split(",").size > 1
      elsif RECORD_TYPE_ASSERTIONS.key?("#{@record_type}-#{canonical_field}")
        @sql = @sql.where(RECORD_TYPE_ASSERTIONS["#{@record_type}-#{canonical_field}"])
      elsif WHERE_ASSERTION_HASH.key?(canonical_field)
        debug("assertion: #{WHERE_ASSERTION_HASH[canonical_field]}")
        @sql = @sql.where(WHERE_ASSERTION_HASH[canonical_field])
      elsif WHERE_INTEGER_VALUE_HASH.key?(canonical_field)
        @sql = @sql.where(WHERE_INTEGER_VALUE_HASH[canonical_field], canonical_value.to_i)
      elsif WHERE_VALUE_HASH_2_VALUES.key?(canonical_field)
        @sql = @sql.where(WHERE_VALUE_HASH_2_VALUES[canonical_field], canonical_value.downcase,
                          canonical_value.downcase)
      else
        unless WHERE_VALUE_HASH.key?(canonical_field)
          raise "No way to handle field: '#{canonical_field}' in an author search."
        end

        @sql = @sql.where(WHERE_VALUE_HASH[canonical_field], canonical_value)
      end
    end
  end

  def canon_value(value)
    value.tr("*", "%")
  end

  def canon_field(field)
    if WHERE_INTEGER_VALUE_HASH.key?(field)
      field
    elsif WHERE_ASSERTION_HASH.key?(field)
      field
    elsif RECORD_TYPE_ASSERTIONS.key?("#{@record_type}-#{field}")
      field
    elsif WHERE_VALUE_HASH.key?(field)
      field
    elsif WHERE_VALUE_HASH_2_VALUES.key?(field)
      field
    elsif CANONICAL_FIELD_NAMES.value?(field)
      field
    elsif CANONICAL_FIELD_NAMES.key?(field)
      CANONICAL_FIELD_NAMES[field]
    else
      raise "Cannot audit authors for: #{field}" unless CANONICAL_FIELD_NAMES.key?(field)
    end
  end

  WHERE_INTEGER_VALUE_HASH = {
    "limit:" => "limit = ?"
  }.freeze

  WHERE_ASSERTION_HASH = {}.freeze

  RECORD_TYPE_ASSERTIONS = {
    "author-instances-only:" => "1 = 2",
    "name-instances-only:" => "1 = 2",
    "instance-instances-only:" => "1 = 1",
    "reference-instances-only:" => "1 = 2",
    "author-names-only:" => "1 = 2",
    "name-names-only:" => "1 = 1",
    "instance-names-only:" => "1 = 2",
    "reference-names-only:" => "1 = 2",
    "author-authors-only:" => "1 = 1",
    "name-authors-only:" => "1 = 2",
    "instance-authors-only:" => "1 = 2",
    "reference-authors-only:" => "1 = 2",
    "author-references-only:" => "1 = 2",
    "name-references-only:" => "1 = 2",
    "instance-references-only:" => "1 = 2",
    "reference-references-only:" => "1 = 1",
  }.freeze

  WHERE_VALUE_HASH = {
    "created-by:" => "lower(created_by) like lower(?)",
    "updated-by:" => "lower(updated_by) like lower(?)",
    "created-at:" => "created_at::date = ?",
    "updated-at:" => "updated_at::date = ?",
    "created-since:" => "created_at::date >= ?",
    "updated-since:" => "updated_at::date >= ?",
    "created-after:" => "created_at::date >= ?",
    "updated-after:" => "updated_at::date >= ?",
    "created-before:" => "created_at::date < ?",
    "updated-before:" => "updated_at::date < ?",
    "date-created:" => "date_trunc('day',created_at) = ?",
    "date-last-updated:" => "date_trunc('day',updated_at) = ?",
  }.freeze

  WHERE_VALUE_HASH_2_VALUES = {
    "created-or-updated-by:" =>
    "(lower(created_by) like lower(?) or lower(updated_by) like lower(?))",
    "created-or-updated-at:" => "(created_at::date = ? or updated_at = ?)",
    "not-created-or-updated-by:" =>
    "(lower(created_by) not like lower(?)
    and lower(updated_by) not like lower(?))",
    "date-created-or-last-updated:" =>
    "date_trunc('day',updated_at) = ? or date_trunc('day',updated_at) = ?",
  }.freeze

  CANONICAL_FIELD_NAMES = {
    "by:" => "created-or-updated-by:",
    "not-by:" => "not-created-or-updated-by:",
  }.freeze

  ALLOWS_MULTIPLE_VALUES = {}.freeze
end
