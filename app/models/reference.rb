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
#  Reference entity - books, papers, journals, etc
# == Schema Information
#
# Table name: reference
#
#  id                   :bigint           not null, primary key
#  abbrev_title         :string(2000)
#  bhl_url              :string(4000)
#  citation             :string(4000)
#  citation_html        :string(4000)
#  created_by           :string(255)      not null
#  display_title        :string(2000)     not null
#  doi                  :string(255)
#  edition              :string(100)
#  isbn                 :string(17)
#  iso_publication_date :string(10)
#  issn                 :string(16)
#  lock_version         :bigint           default(0), not null
#  notes                :string(1000)
#  pages                :string(1000)
#  publication_date     :string(50)
#  published            :boolean          default(FALSE), not null
#  published_location   :string(1000)
#  publisher            :string(1000)
#  source_id_string     :string(100)
#  source_system        :string(50)
#  title                :string(2000)     not null
#  tl2                  :string(30)
#  updated_by           :string(1000)     not null
#  uri                  :text
#  valid_record         :boolean          default(FALSE), not null
#  verbatim_author      :string(1000)
#  verbatim_citation    :string(2000)
#  verbatim_reference   :string(1000)
#  volume               :string(100)
#  year                 :integer
#  created_at           :timestamptz      not null
#  updated_at           :timestamptz      not null
#  author_id            :bigint           not null
#  duplicate_of_id      :bigint
#  language_id          :bigint           not null
#  namespace_id         :bigint           not null
#  parent_id            :bigint
#  ref_author_role_id   :bigint           not null
#  ref_type_id          :bigint           not null
#  source_id            :bigint
#
# Indexes
#
#  iso_pub_index                 (iso_publication_date)
#  ref_citation_text_index       (to_tsvector('english'::regconfig, f_unaccent(COALESCE((citation)::text, ''::text)))) USING gin
#  ref_source_index              (namespace_id,source_id,source_system)
#  ref_source_string_index       (source_id_string)
#  ref_system_index              (source_system)
#  reference_author_index        (author_id)
#  reference_authorrole_index    (ref_author_role_id)
#  reference_parent_index        (parent_id)
#  reference_type_index          (ref_type_id)
#  uk_kqwpm0crhcq4n9t9uiyfxo2df  (doi) UNIQUE
#  uk_nivlrafbqdoj0yie46ixithd3  (uri) UNIQUE
#
# Foreign Keys
#
#  fk_1qx84m8tuk7vw2diyxfbj5r2n  (language_id => language.id)
#  fk_3min66ljijxavb0fjergx5dpm  (duplicate_of_id => reference.id)
#  fk_a98ei1lxn89madjihel3cvi90  (ref_author_role_id => ref_author_role.id)
#  fk_am2j11kvuwl19gqewuu18gjjm  (namespace_id => namespace.id)
#  fk_cr9avt4miqikx4kk53aflnnkd  (parent_id => reference.id)
#  fk_dm9y4p9xpsc8m7vljbohubl7x  (ref_type_id => ref_type.id)
#  fk_p8lhsoo01164dsvvwxob0w3sp  (author_id => author.id)
#
class Reference < ActiveRecord::Base
  include PgSearch::Model
  include AuditScopable
  include ReferenceAssociations
  include ReferenceScopes
  include ReferenceValidations
  include ReferenceIsoDateValidations
  include ReferenceIsoDateParts
  include ReferenceRefTypeValidations
  include ReferenceCitations
  require "open-uri"
  self.table_name = "reference"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  strip_attributes

  attr_accessor :display_as, :message

  has_many :products, foreign_key: "reference_id"

  before_validation :set_defaults
  before_create :set_defaults
  before_save :validate

  def children?
    children.size.positive?
  end

  def instances?
    instances.size.positive?
  end

  def validate
    errors[:base].size.zero?
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def anchor_id
    "Reference-#{id}"
  end

  def pages_useless?
    pages.blank? || pages.match(/null - null/)
  end

  def self.find_authors
    ->(name) { Author.where(" lower(name) = lower(?)", name.downcase) }
  end

  def self.find_references
    ->(title) { Reference.where(" lower(title) = lower(?)", title.downcase) }
  end

  def self.dummy_record
    find_by_title("Unknown")
  end

  def display_as_part_of_concept
    self.display_as = :reference_as_part_of_concept
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def published?
    published
  end

  def set_defaults
    self.language_id = Language.default.id if language_id.blank?
    self.display_title = title if display_title.blank?
    self.namespace_id = Namespace.default.id
  end

  def parent_has_same_author?
    parent && author.name
                    .match(/\A#{Regexp.escape(parent.author.name)}\z/)
                    .positive?
  end

  def typeahead_display_value
    type = ref_type.name.downcase
    "#{citation} |#{' [' + pages + ']' unless pages_useless?} [#{type}]"
  end

  def self.count_search_results(raw)
    logger.debug("Counting references")
    just_count_them = true
    count = search(raw, just_count_them)
    logger.debug(count)
    count
  end

  def ref_type_options
    if children.size.zero?
      RefType.options
    else
      RefType.options_for_parent_of(children.collect(&:ref_type))
    end
  end

  def part_parent_year
    return nil unless ref_type.part?

    parent.iso_publication_date
  end

  def iso_pub_date_for_sorting
    iso_publication_date || parent.try("iso_publication_date") || "9999"
  end

  def self.ref_types
    sql = "select rt.name, count(*) total from reference r join ref_type rt on r.ref_type_id = rt.id group by rt.name order by rt.name"
    records_array = ActiveRecord::Base.connection.execute(sql)
  end
end
