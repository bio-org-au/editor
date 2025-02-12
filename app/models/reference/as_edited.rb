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

# Reference insert and update.
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
class Reference::AsEdited < Reference
  include ReferenceAuthorResolvable
  include ReferenceParentResolvable
  include ReferenceDuplicateOfResolvable

  def self.create(params, typeahead_params, username)
    reference = Reference::AsEdited.new(params)
    reference.resolve_typeahead_params(typeahead_params)
    raise reference.errors.full_messages.first.to_s unless reference.save_with_username(username)

    reference.set_citation!

    reference
  end

  def update_if_changed(params, typeahead_params, username)
    assign_attributes(empty_strings_to_nils(params))
    resolve_typeahead_params(typeahead_params)
    if changed?
      apply_change(typeahead_params, username)
    else
      "No change."
    end
  end

  def apply_change(typeahead_params, username)
    if just_setting_duplicate_of_id
      just_set_duplicate_of_id(typeahead_params, username)
    else
      self.updated_by = username
      save!
      set_citation!
      "Updated"
    end
  end

  def just_setting_duplicate_of_id
    changed_attributes.size == 1 && changed_attributes.key?("duplicate_of_id")
  end

  def just_set_duplicate_of_id(params, username)
    if params["duplicate_of_typeahead"].blank?
      update_attribute(:duplicate_of_id, nil)
      update_attribute(:updated_by, username)
      "Duplicate cleared"
    else
      update_attribute(:duplicate_of_id, params["duplicate_of_id"])
      update_attribute(:updated_by, username)
      "Duplicate set"
    end
  end

  # Empty strings as parameters for string fields are interpreted as a change.
  def empty_strings_to_nils(params)
    params.each do |key, value|
      params[key] = nil if value.instance_of?(String) && (value == "")
    end
    params
  end

  def resolve_typeahead_params(params)
    resolve_author(params)
    resolve_parent(params)
    resolve_duplicate_of(params)
  end
end
