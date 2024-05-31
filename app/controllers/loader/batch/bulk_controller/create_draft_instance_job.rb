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
class Loader::Batch::BulkController::CreateDraftInstanceJob
  def initialize(batch_id, search_string, authorising_user, job_number)
    @batch = Loader::Batch.find(batch_id)
    @search_string = search_string
    @authorising_user = authorising_user
    @job_number = job_number
    @search = ::Loader::Name::BulkSearch.new(search_string, batch_id).search
  end

  def run
    log_start
    @job_h = {attempts: 0, creates: 0, declines: 0, errors: 0}
    @search.order(:seq).each do |loader_name|
      do_one_loader_name(loader_name)
    end
    log_finish
    @job_h
  end

  private

  def do_one_loader_name(loader_name)
    @job_h[:attempts] += 1
    creator = ::Loader::Name::MakeOneInstance.new(loader_name,
                                                  @authorising_user,
                                                  @job_number)
    result = creator.create
    @job_h.deep_merge!(result) { |key, old, new| old + new}
  rescue StandardError => e
    entry = "<span class='red'>Error: failed to create instance</span> "
    entry += "##{loader_name.id} #{loader_name.simple_name} "
    entry += "- error in do_one_loader_name: #{e}"
    log(entry)
    @job_h.deep_merge!({errors: 1, errors_reasons: {"#{e.to_s}": 1}}) { |key, old, new| old + new}
  end


  def log(payload)
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @authorising_user).write
  end

  def log_start
    entry = "<b>STARTED</b>: create draft instances for batch: "
    entry += "#{@batch.name} accepted taxa matching #{@search_string}"
    log(entry)
  end

  def log_finish
    entry = "<b>FINISHED</b>: create draft instances for batch: "
    entry += "#{@batch.name} accepted taxa matching #{@search_string}"
    entry += "#{@job_h.to_html_list.html_safe}"
    log(entry)
  end

  def debug(s)
    tag = "Loader::Name::CreateDraftInstanceJob"
    Rails.logger.debug("#{tag}: #{s}")
  end
end
