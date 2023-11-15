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
class OrchidsBatchController < ApplicationController
  before_action :set_accepted_excluded_mode,
                only: %i[index submit create_preferred_matches
                         create_instances_for_preferred_matches
                         add_instances_to_draft_tree]
  def index; end

  # Form has multiple submit buttons.
  def submit
    remember_taxon_string
    case params[:submit].downcase
    when "show status"
      show_status
    else
      change_data
    end
  end

  def enable_add; end

  def disable_add; end

  def unlock
    OrchidBatchJobLock.unlock!
    render js: "$('#emergency-unlock-link').hide();"
  end

  def create_preferred_matches
    prefix = the_prefix("create-preferred-matches-")
    attempted, records = Orchid.create_preferred_matches(params[:taxon_string], @current_user.username,
                                                         @work_on_accepted)
    @message = "Created #{records} matches out of #{attempted} records matching the string '#{params[:taxon_string]}'"
    OrchidBatchJobLock.unlock!
    render "create", locals: { message_container_id_prefix: prefix }
  rescue StandardError => e
    logger.error("OrchidsBatchController#create_preferred_matches: #{e}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    render "error", locals: { message_container_id_prefix: prefix }
  end

  def create_instances_for_preferred_matches
    prefix = the_prefix("create-draft-instances-")
    records, errors = Orchid.create_instance_for_accepted_or_excluded(params[:taxon_string], @current_user.username,
                                                                      @work_on_accepted)
    @message = "Created #{records} draft #{'instance'.pluralize(records)} for #{params[:taxon_string]}"
    OrchidBatchJobLock.unlock!
    render "create", locals: { message_container_id_prefix: prefix }
  rescue StandardError => e
    logger.error("OrchidsBatchController#create_instances_for_preferred_matches: #{e}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    render "error", locals: { message_container_id_prefix: prefix }
  end

  def add_instances_to_draft_tree
    prefix = the_prefix("add-instances-to-tree-")
    logger.debug("#add_instances_to_draft_tree start")
    placed_tally, error_tally, preflight_stop_tally, text_message = Orchid.add_to_tree_for(@working_draft,
                                                                                           params[:taxon_string], @current_user.username, @work_on_accepted)
    logger.debug("records added to tree: #{placed_tally}")
    message(placed_tally, error_tally, preflight_stop_tally, text_message)
    OrchidBatchJobLock.unlock!
    render "create", locals: { message_container_id_prefix: prefix }
  rescue StandardError => e
    logger.error("OrchidsBatchController#add_instances_to_draft_tree: #{e}")
    logger.error e.backtrace.join("\n")
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    render "error", locals: { message_container_id_prefix: prefix }
  end

  def work_on_excluded
    session[:orchids_work_on_excluded] = true
    session[:orchids_work_on_accepted] = false
  end

  def work_on_accepted
    session[:orchids_work_on_accepted] = true
    session[:orchids_work_on_excluded] = false
  end

  private

  def change_data
    raise OrchidBatchJobLockedError, params[:submit] unless OrchidBatchJobLock.lock!(params[:submit])

    case params[:submit]
    when "Create Preferred Matches"
      create_preferred_matches
    when "Create Draft Instances"
      create_instances_for_preferred_matches
    when "Add to draft tree"
      add_instances_to_draft_tree
    else
      OrchidBatchJobLock.unlock!
      throw "Editor doesn't understand what you're asking for: #{params[:submit]}"
    end
  rescue StandardError => e
    logger.error("change_data error: #{e}")
    @message = e.to_s.sub("uncaught throw", "").gsub('"', "")
    render "error", locals: { message_container_id_prefix: "orchid-batch-status-" }
  end

  def remember_taxon_string
    session[:taxon_string] = params[:taxon_string] unless params[:taxon_string].blank?
  end

  def show_status
    @status = Orchid::AsStatusReporter.new(params[:taxon_string], @work_on_accepted).report
    render "status"
  end

  def message(placed_tally, error_tally, preflight_stop_tally, text_msg)
    @message = %(Added to tree: #{placed_tally}; )
    @message += %(Errors: #{error_tally}; )
    @message += %( Stopped preflight: #{preflight_stop_tally})
    @message += %(; #{text_msg})
  end

  def orchid_batch_params
    return nil if params[:orchid_batch].blank?

    params.require(:orchid_batch).permit(:taxon_string, :gui_submit_place)
  end

  def debug(_msg)
    logger.debug("OrchidsBatchController")
  end

  def the_prefix(str)
    if params[:gui_submit_place].nil?
      str
    else
      "#{params[:gui_submit_place]}-#{str}"
    end
    str
  end

  def set_accepted_excluded_mode
    if session[:orchids_work_on_accepted] == true
      @work_on_accepted = true
      @work_on_excluded = false
      session[:orchids_work_on_excluded] = false
    elsif session[:orchids_work_on_excluded] == true
      @work_on_accepted = false
      @work_on_excluded = true
      session[:orchids_work_on_accepted] = false
    else
      @work_on_accepted = true
      @work_on_excluded = false
      session[:orchids_work_on_accepted] = true
      session[:orchids_work_on_excluded] = false
    end
  end
end

class OrchidBatchJobLockedError < StandardError
  def initialize(tag = "unknown", exception_type = "custom")
    @exception_type = exception_type
    super("Cannot run #{tag} because orchid batch jobs are locked.")
  end
end
