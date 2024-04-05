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

# Remove a conflicting synonym
class Loader::Batch::BulkController::RemoveSynConflictsJob
  def initialize(batch_id, search_string, authorising_user, job_number)
    @batch = Loader::Batch.find(batch_id)
    @search_string = search_string
    @authorising_user = authorising_user
    @job_number = job_number
    @search = ::Loader::Name::BulkSynConflictsSearch.new(search_string, batch_id).search
  end


  def run
    log_start
    @job_h = {attempts: 0, creates: 0, declines: 0, errors: 0}
    @search.order(:seq).each do |tree_join_record|
      if preflight_checks_pass?(tree_join_record) 
        do_one_instance(tree_join_record)
        sleep(20)
      end
    end
    log_finish
    @job_h
  end

  private
 
  def preflight_checks_pass?(tree_join_record)
    preflight_check_for_sub_taxa(tree_join_record)
    true
  rescue => e
    log_preflight_decline_to_table(tree_join_record, e.to_s)
    result_h = {attempts: 1, declines: 1, decline_reasons: {"#{e.to_s}": 1}}
    @job_h.deep_merge!(result_h) { |key, old, new| old + new}
    false
  end

  def preflight_check_for_sub_taxa(tree_join_record)
    raise "has sub-taxa" if tree_join_record.has_sub_taxa_in_draft_accepted_tree?
  end

  def log_preflight_decline_to_table(tree_join_record, error)
    content = "#{tree_join_record.name} declined because #{error}"
    Loader::Batch::Bulk::JobLog.new(@job_number, content, @authorising_user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't save log to bulk processing log table: #{e}")
  end

  def do_one_instance(tree_join_record)
    @job_h[:attempts] += 1
    taxo_remover = ::Loader::Name::DraftTaxonomyRemover.new(tree_join_record,
                                                        @working_draft,
                                                        @authorising_user,
                                                        @job_number)
    result = taxo_remover.remove
    @job_h.deep_merge!(taxo_remover.result_h) { |key, old, new| old + new}
 
  rescue StandardError => e
    Rails.logger.error(e.to_s)
    entry = "<span class='red'>Error: failed to remove syn confli t</span>"
    entry += "##{tree_join_record} - error in do_one_instance: #{e}"
    log(entry)
    @job_h.deep_merge({errors: 1}) { | key, old, new | old + new }
  end

  def log(payload)
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @authorising_user).write
  end

  def log_start
    entry = "<b>STARTED</b>: remove syn conflicts for batch: "
    entry += "#{@batch.name} syn conflicts matching #{@search_string}"
    log(entry)
  end

  def log_finish
    entry = "<b>FINISHED</b>: remove syn conflicts for batch: "
    entry += "#{@batch.name} syn conflicts matching #{@search_string}; "
    entry += "#{@job_h.to_html_list.html_safe}"
    log(entry)
  end

  def debug(s)
    tag = "Loader::Name::AsRemoveSynConflictsJob"
    Rails.logger.debug("#{tag}: #{s}")
  end
end
