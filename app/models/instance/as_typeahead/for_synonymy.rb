# frozen_string_literal: true

#   Copyright 2017 Australian National Botanic Gardens
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
# Return array of instances based primarily on full_name
# but additionally on reference.iso_publication_date.
#
# Take a string of search terms like "podolepis jaceoides 1957".
# Match the iso_publication_date component against reference.iso_publication_date and the
# non-year component against name.full_name in a join
# on instance.
# Can also handle strings like:
#   '1957 podolepis jaceoides'
#   'podolepis 1957 jaceoides'
#
# But disordered name fragments, like
#   'jac podolepis'
# do not work because the text part
# is not currently broken into independently
# matched fragments.
#
# Ordering: NSL-1103: added ordering by year.
class Instance::AsTypeahead::ForSynonymy
  attr_reader :results

  COLUMNS = " name.full_name, reference.citation,  " \
            "reference.iso_publication_date, instance.page, " \
            "instance.id, instance.source_system,  " \
            "instance_type.name as instance_type_name"
  SEARCH_LIMIT = 50

  def initialize(terms, name_id)
    @results = []
    @name_binds = []
    terms_without_year = terms.gsub(/[1,2][0-9]{3}/, "").strip.gsub("  ", " ")
    Rails.logger.debug("terms_without_year: #{terms_without_year}")
    return if terms_without_year.blank?

    @name_binds.push(" lower(f_unaccent(full_name)) like lower(f_unaccent(?)) ")
    @name_binds.push(terms_without_year.tr("*", "%") + "%")
    @results = run_query(terms, name_id)
  end

  def run_query(terms, name_id)
    build_query(terms, name_id).collect do |i|
      { value: display_value(i), id: i.id }
    end
  end

  def build_query(terms, name_id)
    query = Instance.select(COLUMNS)
                    .joins(name: :name_rank).where(@name_binds)
                    .joins(:reference).where(reference_binds(terms))
                    .joins(:instance_type)
                    .where("cited_by_id is null")
                    .order(Arel.sql("name_rank.sort_order,lower(f_unaccent(full_name)), iso_publication_date"))
                    .limit(SEARCH_LIMIT)
    restrict_ranks(query, name_id)
  end

  # Only offer names of equal or lesser rank than that of the name of which
  # they are synonyms, but also limit the list to names that rank above the
  # next major rank.
  #
  # For example, adding synonymy in an instance in which Nothofagus (a genus)
  # appears I would prefer to only be offered other genera and other subgeneric
  # names (e.g. sections), but NOT families (higher rank) or above, and NOT
  # species (next lowest major rank) or below.
  #
  # Unranked doesn't fit this pattern, so treat it differenty.
  #
  def restrict_ranks(query, name_id)
    name = Name.find(name_id)
    if name.name_rank.unranked?
      query.merge(NameRank.not_deprecated)
    elsif name.name_rank.infraspecific?
      query.merge(NameRank.infraspecific)
    elsif name.name_rank.infrageneric?
      query.merge(NameRank.infrageneric)
    elsif name.name_rank.infrafamilial?
      query.merge(NameRank.infrafamilial)
    else # not restricted
      query
    end
  end

  def display_value(i)
    value = "#{i.full_name} in #{i.citation}:#{i.iso_publication_date}"
    value += " [#{i.page}]" unless i.page.blank? || i.page.match(/null - null/)
    value += " [#{i.instance_type_name}]" unless i.instance_type_name == "secondary reference"
    value
  end

  def reference_binds(terms)
    reference_binds = []
    match = terms.match(/[1,2][0-9]{3}/)
    return reference_binds if match.blank?

    reference_year = match.to_s 
    if reference_year.present? &&
       reference_year.to_i > 1000 && reference_year.to_i < 3000
      reference_binds.push(" iso_publication_date like ? ||'%' ")
      reference_binds.push(reference_year)
    end
    reference_binds
  end
end
