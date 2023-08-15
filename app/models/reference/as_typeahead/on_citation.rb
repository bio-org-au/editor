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

# Reference typeahead on_citation
class Reference::AsTypeahead::OnCitation
  # Tokenize search terms so word order is not important.
  # Recognise repeated search tokens
  # e.g. walsh in walsh should check for 2 walshes
  # Allow for an ID to exclude, but default it to a meaningless value
  # but not null.
  attr_reader :results

  SEARCH_LIMIT = 50
  def initialize(terms, excluded_id = -1)
    # Rails.logger.debug("Reference::AsTypeahead::OnCitation: initialize; terms: #{terms}")
    # Rails.logger.debug(query(terms, excluded_id).class)
    @results = query(terms, excluded_id).collect do |ref|
      { value: ref.typeahead_display_value,
        id: ref.id.to_s }
    end
  end

  private

  def bound_terms_array(terms)
    where = ""
    binds = []
    terms = terms.tr("*", "%")
    terms_as_frequency_hash(terms).each do |hash|
      where += " lower(f_unaccent(citation)) like lower(f_unaccent(?)) and "
      search_term = "#{hash[:value]}%" * hash[:freq]
      binds.push "%#{search_term}"
    end
    where += " 1=1 "
    binds.unshift(where)
  end

  def terms_as_frequency_hash(terms)
    terms_array = terms.split
    terms_uniq = terms_array.uniq
    terms_uniq.collect do |uniq_term|
      { value: uniq_term, freq: terms_array.count(uniq_term) }
    end
  end

  def query(terms, excluded_id)
    Reference.includes(:ref_type)
             .where.not(ref_type: { name: "Journal" })
             .not_duplicate
             .where.not(reference: { id: excluded_id })
             .where(bound_terms_array(terms))
             .order("citation")
             .limit(SEARCH_LIMIT)
  end
end
