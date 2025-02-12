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
# == Schema Information
#
# Table name: name
#
#  id                    :bigint           not null, primary key
#  apni_json             :jsonb
#  changed_combination   :boolean          default(FALSE), not null
#  created_by            :string(50)       not null
#  full_name             :string(512)
#  full_name_html        :string(2048)
#  lock_version          :bigint           default(0), not null
#  name_element          :string(255)
#  name_path             :text             default(""), not null
#  orth_var              :boolean          default(FALSE), not null
#  published_year        :integer
#  simple_name           :string(250)
#  simple_name_html      :string(2048)
#  sort_name             :string(250)
#  source_id_string      :string(100)
#  source_system         :string(50)
#  status_summary        :string(50)
#  updated_by            :string(50)       not null
#  uri                   :text
#  valid_record          :boolean          default(FALSE), not null
#  verbatim_rank         :string(50)
#  created_at            :timestamptz      not null
#  updated_at            :timestamptz      not null
#  author_id             :bigint
#  base_author_id        :bigint
#  basionym_id           :bigint
#  duplicate_of_id       :bigint
#  ex_author_id          :bigint
#  ex_base_author_id     :bigint
#  family_id             :bigint
#  name_rank_id          :bigint           not null
#  name_status_id        :bigint           not null
#  name_type_id          :bigint           not null
#  namespace_id          :bigint           not null
#  parent_id             :bigint
#  primary_instance_id   :bigint
#  sanctioning_author_id :bigint
#  second_parent_id      :bigint
#  source_dup_of_id      :bigint
#  source_id             :bigint
#
# Indexes
#
#  lower_full_name                          (lower((full_name)::text))
#  name_author_index                        (author_id)
#  name_baseauthor_index                    (base_author_id)
#  name_duplicate_of_id_index               (duplicate_of_id)
#  name_exauthor_index                      (ex_author_id)
#  name_exbaseauthor_index                  (ex_base_author_id)
#  name_full_name_index                     (full_name)
#  name_full_name_trgm_index                (full_name) USING gin
#  name_lower_f_unaccent_full_name_like     (lower(f_unaccent((full_name)::text)) varchar_pattern_ops)
#  name_lower_full_name_gin_trgm            (lower((full_name)::text) gin_trgm_ops) USING gin
#  name_lower_simple_name_gin_trgm          (lower((simple_name)::text) gin_trgm_ops) USING gin
#  name_lower_unacent_full_name_gin_trgm    (lower(f_unaccent((full_name)::text)) gin_trgm_ops) USING gin
#  name_lower_unacent_simple_name_gin_trgm  (lower(f_unaccent((simple_name)::text)) gin_trgm_ops) USING gin
#  name_name_element_index                  (name_element)
#  name_name_path_index                     (name_path) USING gin
#  name_parent_id_ndx                       (parent_id)
#  name_rank_index                          (name_rank_id)
#  name_sanctioningauthor_index             (sanctioning_author_id)
#  name_second_parent_id_ndx                (second_parent_id)
#  name_simple_name_index                   (simple_name)
#  name_source_index                        (namespace_id,source_id,source_system)
#  name_source_string_index                 (source_id_string)
#  name_status_index                        (name_status_id)
#  name_system_index                        (source_system)
#  name_type_index                          (name_type_id)
#  uk_66rbixlxv32riosi9ob62m8h5             (uri) UNIQUE
#
# Foreign Keys
#
#  fk_156ncmx4599jcsmhh5k267cjv   (namespace_id => namespace.id)
#  fk_3pqdqa03w5c6h4yyrrvfuagos   (duplicate_of_id => name.id)
#  fk_5fpm5u0ukiml9nvmq14bd7u51   (name_status_id => name_status.id)
#  fk_5gp2lfblqq94c4ud3340iml0l   (second_parent_id => name.id)
#  fk_ai81l07vh2yhmthr3582igo47   (sanctioning_author_id => author.id)
#  fk_airfjupm6ohehj1lj82yqkwdx   (author_id => author.id)
#  fk_bcef76k0ijrcquyoc0yxehxfp   (name_type_id => name_type.id)
#  fk_coqxx3ewgiecsh3t78yc70b35   (base_author_id => author.id)
#  fk_dd33etb69v5w5iah1eeisy7yt   (parent_id => name.id)
#  fk_rp659tjcxokf26j8551k6an2y   (ex_base_author_id => author.id)
#  fk_sgvxmyj7r9g4wy9c4hd1yn4nu   (ex_author_id => author.id)
#  fk_sk2iikq8wla58jeypkw6h74hc   (name_rank_id => name_rank.id)
#  fk_whce6pgnqjtxgt67xy2lfo34    (family_id => name.id)
#  name_basionym_id_fkey          (basionym_id => name.id)
#  name_primary_instance_id_fkey  (primary_instance_id => instance.id)
#
class Name::AsTypeahead < Name
  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.cultivar_parent_suggestions(term, avoid_id, rank_id = -1)
    logger.debug("cultivar_parent_suggestions term: #{term}
                 avoiding: #{avoid_id} for rank: #{rank_id}")
    if term.blank?
      results = []
    else
      query = Name.not_a_duplicate
                  .full_name_like(term)
                  .avoids_id(avoid_id.try("to_i") || -1)
                  .joins(:name_rank)
                  .joins(:name_status)
                  .name_rank_not_deprecated
                  .name_rank_not_infra
                  .name_rank_not_na
                  .name_rank_not_unknown
                  .name_rank_genus_and_below
                  .select_fields_for_typeahead
                  .order_by_full_name
                  .limit(SEARCH_LIMIT)
      query = if rank_id != "undefined" && NameRank.id_is_unranked?(rank_id.to_i)
                query.ranks_for_unranked_assumes_join
              else
                query.name_rank_not_unranked
              end
      query = query.collect do |n|
        { value: "#{n.full_name} | #{n.name_rank_name} ", id: n.id }
      end
      results = query
    end
    results
  end

  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.hybrid_parent_suggestions(term, avoid_id, rank_id = -1)
    logger.debug("hybrid_parent_suggestions term: #{term}
                 avoiding: #{avoid_id} for rank: #{rank_id}")
    term_for_query = term.strip
    if term_for_query.blank?
      results = []
    else
      query = Name.not_a_duplicate
                  .full_name_like(term_for_query)
                  .avoids_id(avoid_id.try("to_i") || -1)
                  .joins(:name_rank)
                  .joins(:name_status)
                  .name_rank_not_deprecated
                  .name_rank_not_infra
                  .name_rank_not_na
                  .name_rank_not_unknown
                  .name_rank_species_and_below
                  .select_fields_for_typeahead
                  .order_by_full_name
                  .limit(SEARCH_LIMIT)
      query = if rank_id != "undefined" && NameRank.id_is_unranked?(rank_id.to_i)
                query.ranks_for_unranked_assumes_join
              else
                query.name_rank_not_unranked
              end
      query = query.collect do |n|
        { value: "#{n.full_name} | #{n.name_rank_name}#{n.pipe_for_name_status}" \
               "#{n.name_status_name} ", id: n.id }
      end
      results = query
    end
    results
  end

  # Rule is to offer species and below, but above the name's rank.
  # If unranked, also offer unranked.
  def self.duplicate_suggestions(term, avoid_id)
    logger.debug("duplicate_suggestions for term: #{term};
                 avoiding: #{avoid_id}")
    if term.blank?
      results = []
    else
      query = Name.not_a_duplicate
                  .full_name_like(term)
                  .avoids_id(avoid_id.to_i)
                  .joins(:name_rank)
                  .joins(:name_status)
                  .select_fields_for_typeahead
                  .limit(SEARCH_LIMIT)
                  .order_by_full_name
      results = query.collect do |n|
        { value: "#{n.full_name} | #{n.name_status_name}", id: n.id }
      end
    end
    results
  end
end
