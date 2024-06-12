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

# Record a preferred matching name for a raw loader name record.
class Loader::Batch::BulkController::AddToDraftTaxonomyJob
  attr_reader :result

  def initialize(batch_id, search_string, working_draft, authorising_user, job_number)
    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @batch = Loader::Batch.find(batch_id)
    @search_string = search_string
    @authorising_user = authorising_user
    @working_draft = working_draft
    @job_number = job_number
    accepted_or_excluded_only = true
    @search = ::Loader::Name::BulkSearch.new(search_string, batch_id, accepted_or_excluded_only).search
  end

  def run
    log_start
    @result = {Job: 'Add to Draft Taxonomy',
               Job_batch: @batch.name,
               Job_search: @search_string,
               attempts: 0, adds: 0, declines: 0, errors: 0}
    @search.order(:seq).each do |loader_name|
      do_one_loader_name(loader_name)
    end
    record_elapsed
    log_finish
  end

  private

   def record_elapsed
    finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @result[:time_seconds] = (finish_time - @start_time).round(1)
    if @result[:time_seconds] > 60
      @result[:time] = "#{((finish_time - @start_time)/60).round} min #{((finish_time - @start_time)%60).round} sec"
    end
  end

  def do_one_loader_name(loader_name)
    @result[:attempts] += 1
    taxo_adder = ::Loader::Name::DraftTaxonomyAdder.new(loader_name,
                                                        @working_draft,
                                                        @authorising_user,
                                                        @job_number)
    result = taxo_adder.add
    @result.deep_merge!(taxo_adder.result_h) { |key, old, new| old + new}
  end

  def log(payload)
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @authorising_user).write
  end

  def log_start
    entry = "<b>STARTED</b>: add to draft taxonomy for batch: "
    entry += "#{@batch.name} taxa matching #{@search_string}"
    log(entry)
  end

  def log_finish
    entry = "<b>FINISHED</b>: add to draft taxonomy for batch: "
    entry += "#{@batch.name} taxa matching #{@search_string}"
    entry += ": #{@result.to_html_list.html_safe}"
    log(entry)
  end

  def debug(s)
    tag = "Loader::Name::AddToDraftTaxonomy"
    Rails.logger.debug("#{tag}: #{s}")
  end
end
