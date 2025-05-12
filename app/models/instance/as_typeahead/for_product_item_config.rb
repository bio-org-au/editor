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
class Instance::AsTypeahead::ForProductItemConfig
  attr_reader :instances

  def initialize(product_item_config_id:, term:)
    @instances = []
    return if product_item_config_id.blank?

    @instances = Instance.find_by_sql([
      sql_string,
      product_item_config_id.to_i,
      ActiveRecord::Base::sanitize_sql(term),
      ActiveRecord::Base::sanitize_sql(term)]
    ).collect do |i|
      { value: display_value(i), id: i.id, profile_item_id: i.pid}
    end
  end

  private

  def sql_string
    "SELECT DISTINCT i.id, name.full_name, r.citation, r.iso_publication_date, i.source_system, pi.id as pid
      FROM instance i
      INNER JOIN profile_item pi ON pi.instance_id = i.id
      INNER JOIN product_item_config pic ON pic.id = pi.product_item_config_id
      INNER JOIN reference r ON r.id = i.reference_id
      INNER JOIN name ON i.name_id = name.id
      WHERE pic.id = ?
      AND i.draft = false
      AND pi.is_draft = false AND pi.statement_type = 'fact'
      AND (lower(r.citation) like lower('%'||?||'%') or lower(f_unaccent(name.full_name)) like lower('%'||?||'%')) order by r.iso_publication_date"

  end

  def display_value(i)
    "#{i.full_name} in #{i.citation}:#{i.iso_publication_date}"
  end

end
