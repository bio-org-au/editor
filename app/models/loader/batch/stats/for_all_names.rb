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

# Batch Statistics report
# Returns a hash
class Loader::Batch::Stats::ForAllNames
  def initialize(name_string, batch_id)
    @name_string = name_string.downcase.gsub(/\*/, "%")
    @batch_id = batch_id
    core_search
    @report = {}
  end

  def report
    beginning
    middle
    end_part
    @report
  end

  def beginning
    @report[:search] = search
    @report[:lock] = { status: lock_status }
    @report[:record_types] = record_types
    @report[:no_further_processing_by_record_type] =
      NoFurtherProcessingByRecordType.new(@core_search).report
  end

  def middle
    @report[:matched] = Matched.new(@core_search).report
    @report[:unmatched] = Unmatched.new(@core_search).report
  end

  def end_part
    @report[:matched_with_decision] = MatchedWithDecision.new(@core_search)
                                                         .report
    @report[:instances] = Instances.new(@core_search).report
    @report[:instances_breakdown] = InstancesBreakdown.new(@core_search).report
  end

  def search
    { string: @name_string,
      reported: Time.now.strftime("%d-%b-%Y %H:%M:%S") }
  end

  def record_types
    { accepted: accepteds,
      excluded: excludeds,
      synonym: synonyms,
      misapplied: misapplieds,
      headings: headings,
      none_of_the_above: none_of_the_aboves,
      total: names_and_synonyms_count }
  end

  def core_search
    new_core_search
  end

  def old_core_search
    @core_search = 
    if @name_string.match(/\Afamily:/i)
      family_string = @name_string.sub(/\Afamily: */i, "")
      Loader::Name.family_string_search(family_string)
                  .joins(:loader_batch)
                  .where(loader_batch: { id: @batch_id })
    else
      Loader::Name.bulk_operations_search(@name_string)
                  .joins(:loader_batch)
                  .where(loader_batch: { id: @batch_id })
    end
  end

  def new_core_search
    @core_search = Loader::Name::BulkSearch.new(@name_string, @batch_id).search
  end

  def names_and_synonyms_count
    @core_search.count
  end

  def lock_status
    Loader::Batch::Bulk::JobLock.locked? ? "Locked" : "Unlocked"
  end

  def accepteds
    @core_search.where("record_type = 'accepted'").count
  end

  def excludeds
    @core_search.where("record_type = 'excluded'").count
  end

  def synonyms
    @core_search.where("record_type = 'synonym'").count
  end

  def misapplieds
    @core_search.where("record_type = 'misapplied'").count
  end

  def headings
    @core_search.where("record_type = 'heading'").count
  end

  def none_of_the_aboves
    @core_search.where("record_type not in " +
                      " ('accepted','excluded','synonym','misapplied'," +
                      "'heading')")
               .count
  end
end
