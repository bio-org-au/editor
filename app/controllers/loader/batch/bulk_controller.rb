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
  before_action :set_up_job, only: %i[create_preferred_matches
                                      create_draft_instances
                                      add_to_draft_taxonomy]

  before_action :add_name_string_to_session, only: %i[stats
                                                      create_preferred_matches
                                                      create_draft_instances
                                                      add_to_draft_taxonomy]

  rescue_from JobAlreadyLockedError, with: :handle_job_already_locked

  def index
    throw "index"
  end

  def enable_add; end
  def disable_add; end

  def stats
    @stats = Loader::Batch::Stats::Reporter.new(
      params[:name_string],
      (session[:default_loader_batch_id] || 0)
    )
  rescue StandardError => e
    prefix = "bulk-ops-stats-"
    @message = e.to_s
    render :error, locals: { message_container_id_prefix: prefix }
  end

  def create_preferred_matches
    prefix = "create-preferred-matches-"
    run_create_preferred_matches
    Loader::Batch::Bulk::JobLock.unlock!
    render "create_preferred_matches", locals: { message_container_id_prefix: prefix }
  rescue StandardError => e
    pull_down_job
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    render "error", locals: { message_container_id_prefix: prefix }
  end

  def create_draft_instances
    prefix = "create-draft-instances-"
    run_create_draft_instances
    Loader::Batch::Bulk::JobLock.unlock!
    render "create_draft_instances", locals: { message_container_id_prefix: prefix }
  rescue StandardError => e
    pull_down_job
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    render "error", locals: { message_container_id_prefix: prefix }
  end

  def add_to_draft_taxonomy
    prefix = "add-to-draft-taxonomy-"
    run_add_to_draft_taxonomy
    Loader::Batch::Bulk::JobLock.unlock!
    render "add_to_draft_taxonomy", locals: { message_container_id_prefix: prefix }
  rescue StandardError => e
    pull_down_job
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    render "error", locals: { message_container_id_prefix: prefix }
  end

  private

  def run_create_preferred_matches
    @message_h = CreatePreferredMatchesJob.new(
      session[:default_loader_batch_id],
      params[:name_string],
      @current_user.username,
      @job_number
    ).run
  end

  def run_create_draft_instances
    @message_h = CreateDraftInstanceJob.new(session[:default_loader_batch_id],
                                            params[:name_string],
                                            @current_user.username,
                                            @job_number).run
  end

  def run_add_to_draft_taxonomy
    job = AddToDraftTaxonomyJob.new(session[:default_loader_batch_id],
                                    params[:name_string],
                                    @working_draft,
                                    @current_user.username,
                                    @job_number)
    job.run
    @message_h = job.result
  end

  def add_name_string_to_session
    return if params[:name_string].blank?

    session[:name_string] = params[:name_string]
  end

  def clean_params
    params[:name_string] = params[:name_string].try("strip")
  end

  def set_up_job
    @job_number = Time.now.to_i
    return if Loader::Batch::Bulk::JobLock.lock!(params[:submit])

    raise JobAlreadyLockedError, params[:submit]
  end

  def pull_down_job
    Loader::Batch::Bulk::JobLock.unlock!
  end

  def handle_job_already_locked
    logger.error("Job already locked error")
    @message = "Job Already Locked"
    render :job_already_locked_error
  end
end
