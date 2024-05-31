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
  DECLINED_REMOVE = "<span class='firebrick'>Declined to remove conflict</span>"
  def initialize(batch_id, search_string, authorising_user, job_number)
    @batch = Loader::Batch.find(batch_id)
    @search_string = search_string.downcase
    @authorising_user = authorising_user
    @job_number = job_number
    @search = ::Loader::Name::BulkSynConflictsSearch.new(@search_string, batch_id).search
  end

  def run
    log_start
    @job_h = {attempts: 0, creates: 0, declines: 0, errors: 0}
    @search.order(:seq).each do |tree_join_record|
      if preflight_checks_pass?(tree_join_record) 
        do_one_instance(tree_join_record)
        # trial to avoid catastrophic failures in Services/Mapper
        sleep(Rails.configuration.try('bulk_job_delay_seconds') || 5)
      end
    end
    log_finish
    @job_h
  rescue StandardError => e
    Rails.logger.error("Loader::Batch::BulkController::RemoveSynConflictsJob.run: #{e}")
    @job_h
  end

  private
 
  def preflight_checks_pass?(tree_join_record)
    preflight_check_for_sub_taxa(tree_join_record)
    preflight_check_for_nfp(tree_join_record)
    true
  rescue => e
    log_preflight_decline_to_table(tree_join_record, e.to_s)
    result_h = {attempts: 1, declines: 1, declines_reasons: {"#{e.to_s}": 1}}
    @job_h.deep_merge!(result_h) { |key, old, new| old + new}
    false
  end

  def preflight_check_for_sub_taxa(tree_join_record)
    raise "declined - has sub-taxa" if tree_join_record.has_sub_taxa_in_draft_accepted_tree?
  end

  def preflight_check_for_nfp(tree_join_record)
    loader_name = Loader::Name.find(tree_join_record.loader_name_id)
    raise "declined - NFP" if loader_name.no_further_processing?
  end

  def log_preflight_decline_to_table(tree_join_record, decline_info)
    content = "#{DECLINED_REMOVE} - #{tree_join_record.element_link} #{tree_join_record.simple_name} #{decline_info}"
    log_to_table(content)
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
    Rails.logger.error("Loader::Batch::BulkController::RemoveSynConflictsJob.do_one_instance: #{e}")
    entry = "<span class='red'>Error: remove syn conflict failed</span>: #{e}"
    content = "#{tree_join_record.element_link} #{tree_join_record.simple_name} #{entry}"
    log_to_table(content)
    @job_h.deep_merge!({errors: 1, errors_reasons: {"#{e.to_s}": 1}}) { | key, old, new | old + new }
  end

  def log_to_table(payload)
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @authorising_user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't save log to bulk processing log table: #{e}")
  end

  def log_start
    entry = "<b>STARTED</b>: remove syn conflicts for batch: "
    entry += "#{@batch.name} syn conflicts matching #{@search_string}"
    log_to_table(entry)
  end

  def log_finish
    entry = "<b>FINISHED</b>: remove syn conflicts for batch: "
    entry += "#{@batch.name} syn conflicts matching #{@search_string}; "
    entry += "#{@job_h.to_html_list.html_safe}"
    log_to_table(entry)
  end

  def debug(s)
    tag = "Loader::Name::AsRemoveSynConflictsJob"
    Rails.logger.debug("#{tag}: #{s}")
  end
end
