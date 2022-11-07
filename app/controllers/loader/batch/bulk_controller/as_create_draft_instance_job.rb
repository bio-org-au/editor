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
class Loader::Batch::BulkController::AsCreateDraftInstanceJob
  def initialize(batch_id, search_string, authorising_user, work_on_accepted,
                 job_number)
    @batch = Loader::Batch.find(batch_id)
    @search_string = search_string
    @authorising_user = authorising_user
    @work_on_accepted = work_on_accepted
    @job_number = job_number
  end

  # Loader::Name.create_instance_for_accepted_or_excluded(params[:taxon_string], @current_user.username, @work_on_accepted)
  # def self.create_instance_for_accepted_or_excluded(taxon_s, authorising_user, work_on_accepted)
  def run
    if @work_on_accepted
      @search = Loader::Name.taxon_string_search_no_excluded(@batch, @search_string)
    else
      @search = Loader::Name.taxon_string_search_for_excluded(@batch, @search_string)
    end
    return create_draft_instances
  end

  private

  def create_draft_instances
    log_start
    @attempts = @creates = @declines = @errors = 0
    @search.order(:seq).each do |loader_name|
      do_one_loader_name(loader_name)
    end
    log_finish
    return @attempts, @creates, @declines, @errors
  end

  def do_one_loader_name(loader_name)
    @attempts += 1
    creator = ::Loader::Name::AsInstanceCreator.new(loader_name,
                                                    @authorising_user,
                                                    @job_number)
    @result = creator.create
    record_result(loader_name)
  rescue => e
    raise
    entry = "Failed to create instance for #{loader_name.simple_name} "
    entry += "##{loader_name.id} - error in do_one_loader_name: #{e.to_s}"
    log(entry)
    raise
    #return [0,0,1]
  end

  def log(payload)
    entry = "Job ##{@job_number}: #{payload}"
    BulkProcessingLog.log(entry, "Bulk job for #{@authorising_user}")
  end

  def log_start
    entry = "Started create draft instances for batch: "
    entry += "#{@batch.name} accepted taxa matching #{@search_string}"
    log(entry)
  end

  def log_finish
    entry = "Finished; records attempted: #{@attempts}; "
    entry += "records created: #{@creates}; "
    entry += "declined: #{@declines}; errors: #{@errors}"
    log(entry)
  end

  def record_result(loader_name)
    tally_result_parts
  end

  def tally_result_parts
    @creates += @result.first
    @declines += @result.second
    @errors += @result.last
  end

  def debug(s)
    tag = "Loader::Name::AsCreateDraftInstanceJob" 
    Rails.logger.debug("#{tag}: #{s}")
  end
end
