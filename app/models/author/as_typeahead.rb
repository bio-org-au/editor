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

# Author as Typeahead
# TODO: break into one-class-per-typeahead
class Author::AsTypeahead < Author
  SEARCH_LIMIT = 50

  def self.on_abbrev(term)
    if term.blank?
      []
    else
      Author.lower_abbrev_like(term + "%") \
            .where("duplicate_of_id is null") \
            .order("abbrev").limit(SEARCH_LIMIT) \
            .collect { |n| { value: n.abbrev.to_s, id: n.id.to_s } }
    end
  end

  # Tokenize search terms so word order is not important.
  # Recognise repeated search tokens
  # e.g. walsh in walsh should check for at least 2 walshes
  def self.on_name(terms)
    where = ""
    binds = []
    terms = terms.tr("*", "%")
    terms_array = terms.split
    terms_uniq = terms_array.uniq
    terms_uniq.collect do |uniq_term|
      { value: uniq_term, freq: terms_array.count(uniq_term) }
    end.each do |hash|
      where += " lower(f_unaccent(name)) like lower(f_unaccent(?)) and "
      search_term = "#{hash[:value]}%" * hash[:freq]
      binds.push "%#{search_term}"
    end
    where += " 1=1 "
    Author.not_duplicate
          .where(binds.unshift(where))
          .joins("left outer join reference on reference.author_id = author.id")
          .select("author.name as name, author.id as id, author.abbrev as \
abbrev, count(reference.id) as ref_count")
          .group("lower(author.name),author.id")
          .order("author.name")
          .limit(SEARCH_LIMIT)
          .collect { |n| { value: formatted_search_result(n), id: n.id.to_s } }
  end

  # Based on the on_name method, but also excludes :id passed in.
  # Used for offering duplicates_of records.
  def self.on_name_duplicate_of(term, excluded_id = -1)
    if term.blank?
      []
    else
      Author.lower_name_like(term + "%")
            .not_duplicate
            .where([" author.id <> ?", excluded_id])
            .joins("left outer join reference on " \
                   "reference.author_id = author.id")
            .select("author.name as name, author.id as id, author.abbrev as \
abbrev, count(reference.id) as ref_count")
            .group("lower(author.name),author.id")
            .order("author.name").limit(SEARCH_LIMIT)
            .collect do |n|
              { value: formatted_search_result(n), id: n.id.to_s }
            end
    end
  end

  def self.formatted_search_result(auth)
    result = auth.name
    result << " | #{auth.ref_count} #{'ref'.pluralize(auth.ref_count)}" unless auth.ref_count.zero?
    result << " | #{auth.abbrev}" if auth.abbrev.present?
    result
  end
end
