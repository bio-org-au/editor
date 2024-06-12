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
class Loader::Batch::BulkController::CreatePreferredMatchesJob
  def initialize(batch_id, search_string, authorising_user, job_number)
    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @batch = Loader::Batch.find(batch_id)
    @search_string = search_string
    @authorising_user = authorising_user
    @job_number = job_number
    @search = ::Loader::Name::BulkSearch.new(search_string, batch_id).search
  end

  def run
    log_start
    @job_h = {Job: 'Create Preferred Matches',
              Job_batch: @batch.name,
              Job_search: @search_string,
              attempts: 0, creates: 0, declines: 0, errors: 0}
    @search.order(:seq).each do |loader_name|
      do_one_loader_name(loader_name)
    end
    record_elapsed
    log_finish
    @job_h
  end

  private

  def record_elapsed
    finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @job_h[:time_seconds] = (finish_time - @start_time).round(1)
    if @job_h[:time_seconds] > 60
      @job_h[:time] = "#{((finish_time - @start_time)/60).round} min #{((finish_time - @start_time)%60).round} sec"
    end
  end

  def do_one_loader_name(loader_name)
    @job_h[:attempts] += 1

    matcher = ::Loader::Name::MakeOneMatchTask.new(loader_name,
                                                   @authorising_user,
                                                   @job_number)
    result = matcher.create
    @job_h.deep_merge!(result) { |key, old, new| old + new}
  rescue StandardError => e
    Rails.logger.error(e.to_s)
    entry = "<span class='red'>Error: failed to make preferred match </span>"
    entry += "##{loader_name.id} #{loader_name.simple_name} - error in do_one_loader_name: #{e}"
    log(entry)
    @job_h.deep_merge({errors: 1}) { | key, old, new | old + new }
  end

  def log(payload)
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @authorising_user).write
  end

  def log_start
    entry = "<b>STARTED</b>: create preferred matches for batch: "
    entry += "#{@batch.name} loader names matching #{@search_string}"
    log(entry)
  end

  def log_finish
    entry = "<b>FINISHED</b>: create preferred matches for batch: "
    entry += "#{@batch.name} loader names matching #{@search_string}; "
    entry += "#{@job_h.to_html_list.html_safe}"
    log(entry)
  end

  def debug(s)
    tag = "Loader::Name::AsCreatePreferredMatchesJob"
    Rails.logger.debug("#{tag}: #{s}")
  end
end
