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


class Loader::Batch::Stats::ForAcceptedNames
  def initialize(name_string, batch_id)
    @name_string = name_string.downcase.gsub(/\*/,'%')
    @batch_id = batch_id
  end

  def report
    { search: {string: @name_string,
               reported: Time.now.strftime("%d-%b-%Y %H:%M:%S"),
               category: 'Accepted'},
      lock: { status: lock_status }, 
      core: { accepted: accepteds,
              synonym: synonyms,
              misapplied: misapplieds,
              hybrid_cross: hybrid_crosses,
              total: names_and_synonyms_count },
      other: { no_further_processing: no_further_processing },
      matched: { accepted_with_preferred_match: accepted_with_preferred_match,
                 synonym_with_preferred_match: synonym_with_preferred_match,
                 misapplied_with_a_preferred_match: misapplied_with_a_preferred_match,
                 misapplied_preferred_matches: misapplied_preferred_matches },
      unmatched: { accepted_without_preferred_match: accepted_without_preferred_match,
                   synonym_without_preferred_match: synonym_without_preferred_match,
                   misapplied_without_a_preferred_match: misapplied_without_a_preferred_match },
      with_match_and_instances:
        { accepted_with_standalone: accepted_with_standalone,
          synonym_with_cross_ref: synonym_with_cross_ref,
          misapplied_with_cross_ref: misapplied_with_cross_ref },
      with_match_and_instances_breakdown:
        { accepted_with_standalone_created: accepted_with_standalone_created,
          accepted_with_standalone_found: accepted_with_standalone_found,
          synonym_with_cross_ref_created: synonym_with_cross_ref_created,
          synonym_with_cross_ref_found: synonym_with_cross_ref_found,
          misapp_with_cross_ref_created: misapp_with_cross_ref_created,
          misapp_with_cross_ref_found: misapp_with_cross_ref_found },
    }
  end

  def core_search
    Loader::Name.name_string_search(@name_string)
      .joins(:loader_batch)
      .where(loader_batch: {id: @batch_id})
  end

  def names_and_synonyms_count
    core_search.count
  end

  def lock_status
    Loader::Batch::JobLock.locked? ? 'Locked' : 'Unlocked'
  end

  def accepteds
    core_search.where("record_type = 'accepted' and not doubtful").count
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

  def no_further_processing
    core_search.where(" no_further_processing  or (select no_further_processing from loader_name p where p.id = loader_name.parent_id)")
           .count
  end

  def accepted_with_preferred_match
    core_search.where("record_type = 'accepted'")
               .joins(:loader_name_matches)
               .count
  end

  def accepted_without_preferred_match
    core_search.where("record_type = 'accepted'")
               .where(" not no_further_processing ")
               .where.not("exists (select null from loader_name_match match where loader_name.id = match.loader_name_id)")
               .count
  end

  def synonym_with_preferred_match
    core_search.where("record_type = 'synonym'")
               .joins(:loader_name_matches)
               .count
  end

  def synonym_without_preferred_match
    core_search.where("record_type = 'synonym'")
               .where(" not no_further_processing ")
               .where(" not exists (select null from loader_name parent where loader_name.parent_id = parent.id and parent.no_further_processing)")
               .where.not("exists (select null from loader_name_match match where loader_name.id = match.loader_name_id)")
               .count
  end

  def misapplied_preferred_matches
    core_search.where("record_type = 'misapplied'")
               .where(" not no_further_processing ")
               .joins(:loader_name_matches)
               .count
  end

  def misapplied_with_a_preferred_match
    core_search.where("record_type = 'misapplied'")
               .where("exists (select null from loader_name_match match where loader_name.id = match.loader_name_id)")
               .count
  rescue => e
    e.to_s
  end

  def misapplied_without_a_preferred_match
    core_search.where("record_type = 'misapplied'")
               .where(" not no_further_processing ")
               .where(" not exists (select null from loader_name parent where loader_name.parent_id = parent.id and parent.no_further_processing)")
               .where.not("exists (select null from loader_name_match match where loader_name.id = match.loader_name_id)")
               .count
  rescue => e
    e.to_s
  end

  def accepted_with_standalone
    core_search.where("record_type = 'accepted'")
               .joins(:loader_name_matches)
               .where.not( {loader_name_matches: { standalone_instance_id: nil}})
               .count
  end

  def accepted_with_standalone_created
    core_search.where("record_type = 'accepted'")
               .joins(:loader_name_matches)
               .where( {'loader_name_match': { standalone_instance_created: true}})
               .count
  end

  def accepted_with_standalone_found
    core_search.where("record_type = 'accepted'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { standalone_instance_found: true}})
               .count
  end

  def accepted_without_standalone
    core_search.where("record_type = 'accepted'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { standalone_instance_id: nil}})
               .count
  end

  def synonym_with_cross_ref
    core_search.where("record_type = 'synonym'")
               .joins(:loader_name_matches)
               .where.not( {loader_name_matches: { relationship_instance_id: nil}})
               .count
  end

  def synonym_with_cross_ref_created
    core_search.where("record_type = 'synonym'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { relationship_instance_created: true}})
               .count
  end

  def synonym_with_cross_ref_found
    core_search.where("record_type = 'synonym'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { relationship_instance_found: true}})
               .count
  end

  def misapp_with_cross_ref_created
    core_search.where("record_type = 'misapplied'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { relationship_instance_created: true}})
               .count
  end

  def misapp_with_cross_ref_found
    core_search.where("record_type = 'misapplied'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { relationship_instance_found: true}})
               .count
  end

  def synonym_without_cross_ref
    core_search.where("record_type = 'synonym'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { relationship_instance_id: nil}})
               .count
  end

  def misapplied_with_cross_ref
    core_search.where("record_type = 'misapplied'")
               .joins(:loader_name_matches)
               .where.not( {loader_name_matches: { relationship_instance_id: nil}})
               .count
  end

  def misapplied_without_cross_ref
    core_search.where("record_type = 'misapplied'")
               .joins(:loader_name_matches)
               .where( {loader_name_matches: { relationship_instance_id: nil}})
               .count
  end

  # Note: the name_id column is merely an ugly hack to get the count(*) value.
  # It is _not_ the name_id
  def standalones_in_taxonomy
    sql = "select t.draft_name, count(*) name_id "
    sql += " from loader_name_matches orn "
    sql += " join orchids o "
    sql += " on o.id = orn.orchid_id "
    sql += " join tree_vw t "
    sql += " on orn.standalone_instance_id = t.instance_id "
    sql += " where lower(o.taxon) like ? "
    sql += " and (o.record_type = 'accepted' and not o.doubtful)"
    sql += " and t.current_tree_version_id = t.tree_version_id_fk "
    sql += " group by t.draft_name, published"
    records_array = TreeVw.find_by_sql([sql, @name_string])
    h = Hash.new
    h[:taxonomy_records] = 0 if records_array.empty?
    records_array.each do |rec|
      h["#{rec[:draft_name]}"] = rec[:name_id]  # name_id is a column I'm using for the count
    end
    h
  end
end
