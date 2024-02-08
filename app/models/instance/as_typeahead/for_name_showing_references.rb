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
class Instance::AsTypeahead::ForNameShowingReferences
  attr_reader :references

  def initialize(params)
    @references = []
    return if params[:instance_id].blank?

    @references = Reference.find_by_sql(
      [sql_string,
       params[:instance_id].to_i,
       params[:instance_id].to_i,
       ActiveRecord::Base::sanitize_sql(params[:term])]).collect do |ref|
         { value: formatted_reference(ref), id: ref.id }
       end
  end

  def sql_string
    "select i.id,r.citation,r.iso_publication_date, r.pages, r.source_system,
    t.name instance_type
    from reference r
    inner join author a on r.author_id = a.id
    inner join instance i on r.id = i.reference_id
    inner join instance_type t on i.instance_type_id = t.id
    where i.name_id = (select name_id from instance where id = ?)
      and i.id != ?
      and lower(r.citation) like lower('%'||?||'%') order by r.iso_publication_date,a.name"
  end

  def formatted_reference(ref)
    "#{ref.citation}:#{ref.iso_publication_date} #{formatted_pages(ref)} #{formatted_type(ref)}
    #{'[' + ref.source_system.downcase + ']' unless ref.source_system.blank?}"
  end

  def formatted_pages(ref)
    return "" if ref.pages_useless?

    "[#{ref.pages}]"
  end

  def formatted_type(ref)
    return "" if ref.instance_type == "secondary reference"

    "[#{ref.instance_type}]"
  end

  def formatted_source_system(ref)
    return "" if ref.source_system.blank?

    "[#{ref.source_system.downcase}]"
  end
end
