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

#  We need to place Orchids on a draft tree.
class Orchid::AsStatusReporter::ForExcludedNames
  def initialize(taxon_string)
    @taxon_string = taxon_string.downcase.gsub(/\*/, "%")
  end

  def report
    { search: { search_string: @taxon_string,
                reported_at: Time.now.strftime("%d-%b-%Y %H:%M:%S"),
                name_category: "Excluded" },
      lock: { status: lock_status },
      core: { excluded: excludeds,
              synonym: synonyms,
              misapplied: misapplieds,
              hybrid_cross: hybrid_crosses,
              total: orchids_and_their_synonyms },
      other: { further_processing_prevented: further_processing_prevented },
      matched: { excluded_with_preferred_match: excluded_with_preferred_match,
                 synonym_with_preferred_match: synonym_with_preferred_match,
                 misapplied_with_a_preferred_match: misapplied_with_a_preferred_match,
                 misapplied_preferred_matches: misapplied_preferred_matches },
      unmatched: { excluded_without_preferred_match_and_not_nfp: excluded_without_preferred_match,
                   synonym_without_preferred_match_and_not_nfp: synonym_without_preferred_match,
                   misapplied_without_a_preferred_match_and_not_nfp: misapplied_without_a_preferred_match },
      with_match_and_instances:
        { excluded_matched_with_standalone: excluded_matched_with_standalone,
          synonym_matched_with_cross_ref: synonym_matched_with_cross_ref,
          misapplied_with_cross_ref: misapplied_with_cross_ref },
      with_match_and_instances_breakdown:
        { excluded_matched_with_standalone_instance_created: excluded_matched_with_standalone_instance_created,
          excluded_matched_with_standalone_instance_found: excluded_matched_with_standalone_instance_found,
          synonym_matched_with_cross_ref_created: synonym_matched_with_cross_ref_created,
          synonym_matched_with_cross_ref_found: synonym_matched_with_cross_ref_found,
          misapp_matched_with_cross_ref_created: misapp_matched_with_cross_ref_created,
          misapp_matched_with_cross_ref_found: misapp_matched_with_cross_ref_found },
      with_match_but_without_instances:
        { excluded_matched_without_standalone: excluded_matched_without_standalone,
          synonym_matched_without_cross_ref: synonym_matched_without_cross_ref,
          misapplied_matched_without_cross_ref: misapplied_matched_without_cross_ref },
      excluded_standalone_in_current_taxonomy: standalones_in_taxonomy, }
  end

  def core_search
    Orchid.taxon_string_search_for_excluded(@taxon_string)
  end

  def orchids_and_their_synonyms
    core_search.count
  end

  def lock_status
    OrchidBatchJobLock.locked? ? "Locked" : "Unlocked"
  end

  def excludeds
    core_search.where("record_type = 'accepted' and doubtful").count
  end

  def synonyms
    core_search.where("record_type = 'synonym'").count
  end

  def misapplieds
    core_search.where("record_type = 'misapplied'").count
  end

  def hybrid_crosses
    core_search.where("record_type = 'hybrid_cross'").count
  end

  def further_processing_prevented
    core_search.where(" exclude_from_further_processing  or (select exclude_from_further_processing from orchids p where p.id = orchids.parent_id)")
               .count
  end

  def excluded_with_preferred_match
    core_search.where("record_type = 'accepted' and doubtful")
               .joins(:orchids_name)
               .count
  end

  def excluded_without_preferred_match
    core_search.where("record_type = 'accepted' and doubtful")
               .where(" not exclude_from_further_processing ")
               .where.not("exists (select null from orchids_names orn where orchids.id = orn.orchid_id)")
               .count
  end

  def synonym_with_preferred_match
    core_search.where("record_type = 'synonym'")
               .joins(:orchids_name)
               .count
  end

  def synonym_without_preferred_match
    core_search.where("record_type = 'synonym'")
               .where(" not exclude_from_further_processing ")
               .where(" not exists (select null from orchids parent where orchids.parent_id = parent.id and parent.exclude_from_further_processing)")
               .where.not("exists (select null from orchids_names orn where orchids.id = orn.orchid_id)")
               .count
  end

  def misapplied_preferred_matches
    core_search.where("record_type = 'misapplied'")
               .where(" not exclude_from_further_processing ")
               .joins(:orchids_name)
               .count
  end

  def misapplied_with_a_preferred_match
    core_search.where("record_type = 'misapplied'")
               .where("exists (select null from orchids_names orn where orchids.id = orn.orchid_id)")
               .count
  rescue StandardError => e
    e.to_s
  end

  def misapplied_without_a_preferred_match
    core_search.where("record_type = 'misapplied'")
               .where(" not exclude_from_further_processing ")
               .where(" not exists (select null from orchids parent where orchids.parent_id = parent.id and parent.exclude_from_further_processing)")
               .where.not("exists (select null from orchids_names orn where orchids.id = orn.orchid_id)")
               .count
  rescue StandardError => e
    e.to_s
  end

  def excluded_matched_with_standalone
    core_search.where("record_type = 'accepted'")
               .joins(:orchids_name)
               .where.not({ orchids_names: { standalone_instance_id: nil } })
               .count
  end

  def excluded_matched_with_standalone_instance_created
    core_search.where("record_type = 'accepted' and doubtful")
               .joins(:orchids_name)
               .where({ orchids_names: { standalone_instance_created: true } })
               .count
  end

  def excluded_matched_with_standalone_instance_found
    core_search.where("record_type = 'accepted' and doubtful")
               .joins(:orchids_name)
               .where({ orchids_names: { standalone_instance_found: true } })
               .count
  end

  def excluded_matched_without_standalone
    core_search.where("record_type = 'accepted' and doubtful")
               .joins(:orchids_name)
               .where({ orchids_names: { standalone_instance_id: nil } })
               .count
  end

  def synonym_matched_with_cross_ref
    core_search.where("record_type = 'synonym'")
               .joins(:orchids_name)
               .where.not({ orchids_names: { relationship_instance_id: nil } })
               .count
  end

  def synonym_matched_with_cross_ref_created
    core_search.where("record_type = 'synonym'")
               .joins(:orchids_name)
               .where({ orchids_names: { relationship_instance_created: true } })
               .count
  end

  def synonym_matched_with_cross_ref_found
    core_search.where("record_type = 'synonym'")
               .joins(:orchids_name)
               .where({ orchids_names: { relationship_instance_found: true } })
               .count
  end

  def misapp_matched_with_cross_ref_created
    core_search.where("record_type = 'misapplied'")
               .joins(:orchids_name)
               .where({ orchids_names: { relationship_instance_created: true } })
               .count
  end

  def misapp_matched_with_cross_ref_found
    core_search.where("record_type = 'misapplied'")
               .joins(:orchids_name)
               .where({ orchids_names: { relationship_instance_found: true } })
               .count
  end

  def synonym_matched_without_cross_ref
    core_search.where("record_type = 'synonym'")
               .joins(:orchids_name)
               .where({ orchids_names: { relationship_instance_id: nil } })
               .count
  end

  def misapplied_with_cross_ref
    core_search.where("record_type = 'misapplied'")
               .joins(:orchids_name)
               .where.not({ orchids_names: { relationship_instance_id: nil } })
               .count
  end

  def misapplied_matched_without_cross_ref
    core_search.where("record_type = 'misapplied'")
               .joins(:orchids_name)
               .where({ orchids_names: { relationship_instance_id: nil } })
               .count
  end

  # NOTE: the name_id column is merely an ugly hack to get the count(*) value.
  # It is _not_ the name_id
  def standalones_in_taxonomy
    sql = "select t.draft_name, count(*) name_id "
    sql += " from orchids_names orn "
    sql += " join orchids o "
    sql += " on o.id = orn.orchid_id "
    sql += " join tree_vw t "
    sql += " on orn.standalone_instance_id = t.instance_id "
    sql += " where lower(o.taxon) like ? "
    sql += " and (o.record_type = 'accepted' and o.doubtful)"
    sql += " and (t.current_tree_version_id = t.tree_version_id_fk or not published)"
    sql += " group by t.draft_name, published"
    records_array = TreeJoinVw.find_by_sql([sql, @taxon_string])
    h = {}
    h[:taxonomy_records] = 0 if records_array.empty?
    records_array.each do |rec|
      h["#{rec[:draft_name]}"] = rec[:name_id]  # name_id is a column I'm using for the count
    end
    h
  end
end
