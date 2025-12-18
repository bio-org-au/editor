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
class TreeVersionsController < ApplicationController
  before_action :find_tree_version, only: %i[show tab]

  # GET /tree_vesions/1
  # GET /tree_vesions/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  alias tab show

  # New draft tree version
  # This just collects the details and posts to the services
  def new_draft
    @tree = Tree.find(params[:tree_id])
    raise "#{@tree.name} tree is read only - cannot create any drafts" if @tree.is_read_only?
    raise "#{@tree.name} tree already has a draft - cannot create another draft" unless @tree.has_no_drafts?
    authorize! :create_draft, @tree
    render "new_draft"
  end

  def create_draft
    logger.info "Create a draft tree"
    tree = Tree.find(params[:tree_id])
    raise "#{tree.name} tree is read only - cannot create any drafts" if tree.is_read_only?
    raise "#{tree.name} tree already has a draft - cannot create another draft" unless tree.has_no_drafts?
    authorize! :create_draft, tree
    response = Tree::DraftVersion.create_via_service(params[:tree_id],
                                                     nil,
                                                     params[:draft_name],
                                                     params[:draft_log],
                                                     params[:default_draft],
                                                     current_user.username)
    payload = json_payload(response)
    if payload
      @message = "#{payload.draftName} created."
      @created_version = TreeVersion.find(payload.versionNumber)
      render "create_draft"
    else
      @message = "Something went wrong, no payload."
      render "create_draft_error", status: :bad_request
    end
  rescue CanCan::AccessDenied, RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "create_draft_error", status: :forbidden
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "create_draft_error", status: :bad_request
  rescue => e
    @message = e.to_s
    render "create_draft_error", status: :bad_request
  end

  def edit_draft
    authorize! :edit, @working_draft
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    @diff_link = Tree::AsServices.diff_link(@working_draft.tree.current_tree_version_id, @working_draft.id)
    render "edit_draft"
  end

  def update_draft
    draft_version = Tree::DraftVersion.find(params[:version_id])
    authorize! :update_draft, draft_version
    draft_version.draft_name = params[:draft_name]
    draft_version.log_entry = params[:draft_log]
    if draft_version.changed?
      draft_version.save!
      @working_draft = draft_version # why?
      @message = 'Updated'
    else
      @message = 'No change'
    end
    render "update_draft"
  rescue CanCan::AccessDenied => e
    @message = json_error(e)
    render "create_draft_error", status: :forbidden
  rescue => e
    @message = "#{e} - #{draft_version.errors[:base].join(',')}"
    render "update_draft_error", status: :bad_request
  end

  def form_to_publish
    authorize! :publish, @working_draft
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    render "form_to_publish_draft"
  end

  def publish
    authorize! :publish, @working_draft
    draft_version = Tree::DraftVersion.find(params[:version_id])
    draft_version.log_entry = params[:draft_log]
    response = draft_version.publish(current_user.username, params[:next_draft_name])
    json = json(response)
    if json&.ok
      @message = "#### #{draft_version.draft_name} published as #{draft_version.tree.name} version #{draft_version.id} ####"
      @message += "\nNew draft being created (it may take a couple of minutes to show up)." if json&.autocreate
      @working_draft = nil
      render "publish"
    else
      @message = json_result(response)
      render "publish_error"
    end
  rescue Unauthorized, RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "publish_error", status: :forbidden
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "publish_error", status: :bad_request
  rescue => e
    @message = e.to_s
    render "publish_error", status: :bad_request
  end

  private

  def find_tree_version
    @tree_version = TreeVersion.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the tree version."
    redirect_to tree_versions_path
  end

  def tree_version_params
    params.require(:tree_version).permit(:draft_name)
  end

  def set_tab
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             "tab_details"
           end
    logger.debug("@tab: #{@tab}")
  end

  def set_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end

  def json(result)
    JSON.parse(result.body, object_class: OpenStruct)
  end

  def json_payload(result)
    json = json(result)
    json&.payload
  end
end
