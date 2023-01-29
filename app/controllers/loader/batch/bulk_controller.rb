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

# Bulk operations from the Loader tab.
class Loader::Batch::BulkController < ApplicationController
  before_action :clean_params 

  def index
    throw 'index'
  end

   # Form has multiple submit buttons.
  def operation
    add_name_string_to_session
    case params[:submit].downcase
    when 'show stats'
      show_stats
    when 'refresh stats'
      show_stats
    when 'hide stats'
      hide_stats
    else
      run_job
    end
  end

  def enable_add; end
  def disable_add; end

  private

  def run_job
    @job_number = Time.now.to_i
    raise JobLockedError.new(params[:submit]) unless Loader::Batch::Bulk::JobLock.lock!(params[:submit])
    case params[:submit]
    when 'Create Preferred Matches'
      create_preferred_matches
    when 'Create Draft Instances'
      create_draft_instances
    #when 'Add to draft tree'
    #  add_instances_to_draft_tree
    else 
      Loader::Batch::JobLock.unlock!
      throw "Editor doesn't understand what you're asking for: #{params[:submit]}"
    end
  rescue JobLockedError => e
    logger.error('job lock error')
    @message = 'Job Lock Error'
    render :job_lock_error
  rescue => e
    logger.error("run_job error: #{e.to_s}")
    @message = e.to_s.sub(/uncaught throw/,'').gsub(/"/,'')
    render 'error', locals: {message_container_id_prefix: 'bulk-operations-' }
  end

  def create_preferred_matches
    prefix = the_prefix('create-preferred-matches-')
    job = AsCreatePreferredMatchesJob.new(session[:default_loader_batch_id], 
                                 params[:name_string],
                                 @current_user.username,
                                 @job_number)
    attempted, created, declined, errors = job.run
    @message = "Create preferred matches attempted #{attempted}; "
    @message += "created #{created} preferred #{'match'.pluralize(created)} with"
    @message += " #{declined} declined and #{errors} error(s) for "
    @message += "#{params[:name_string]} (job ##{@job_number})"
    Loader::Batch::Bulk::JobLock.unlock!
    render 'create_preferred_matches', locals: {message_container_id_prefix: prefix }
  rescue => e
    logger.error("LoaderBatchBulkController#create_preferred_matches: #{e.to_s}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s.sub(/uncaught throw/,'').gsub(/"/,'')
    render 'error', locals: {message_container_id_prefix: prefix }
  end

  def create_draft_instances
    prefix = the_prefix('create-draft-instances-')
    job = AsCreateDraftInstanceJob.new(session[:default_loader_batch_id], 
                                 params[:name_string],
                                 @current_user.username,
                                 @job_number)
    attempted, created, declined, errors = job.run
    @message = "Create draft instances attempted #{attempted}; "
    @message += "created #{created} draft #{'instance'.pluralize(created)} with"
    @message += " #{declined} declined and #{errors} error(s) for "
    @message += "#{params[:name_string]} (job ##{@job_number})"
    Loader::Batch::Bulk::JobLock.unlock!
    render 'create_draft_instances', locals: {message_container_id_prefix: prefix }
  rescue => e
    logger.error("LoaderBatchBulkController#create_draft_instances: #{e.to_s}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s.sub(/uncaught throw/,'').gsub(/"/,'')
    render 'error', locals: {message_container_id_prefix: prefix }
  end

  def add_name_string_to_session
    unless params[:name_string].blank?
      session[:name_string] = params[:name_string]
    end
  end

  def show_stats
    @stats = Loader::Batch::Stats::Reporter.new(
      params[:name_string],
      (session[:default_loader_batch_id]||0))
    render 'stats'
  end

  def hide_stats
    render 'hide_stats'
  end

  def the_prefix(str)
    if params[:gui_submit_place].nil?
      str
    else
      "#{params[:gui_submit_place]}-#{str}"
    end
    str
  end

  def clean_params
    params[:name_string] = params[:name_string].try('strip')
  end
end

