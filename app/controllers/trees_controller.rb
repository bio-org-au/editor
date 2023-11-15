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

#   Trees are classification graphs for taxa.
#   There are several types of trees - see the model.
class TreesController < ApplicationController
  before_action :find_tree, only: %i[show tab]
  def index; end

  # GET /trees/1
  # GET /trees/1.json
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    logger.debug("TreesController#show for tree: #{@tree}")
    pick_a_tab("tab_details")
    # pick_a_tab_index
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end
  alias tab show

  # New draft tree
  # This just collects the details and posts to the services
  def new_draft
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    render "new_draft"
  end

  def create_draft
    logger.info "Create a draft tree"
    response = Tree::DraftVersion.create(params[:tree_id],
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
      render "create_draft_error"
    end
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "create_draft_error"
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "create_draft_error"
  end

  def edit_draft
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    @diff_link = Tree::AsServices.diff_link(@working_draft.tree.current_tree_version_id, @working_draft.id)
    render "edit_draft"
  end

  def update_draft
    logger.info "Update a draft tree"
    target = Tree::DraftVersion.find(params[:version_id])
    target.draft_name = params[:draft_name]
    target.log_entry = params[:draft_log]
    target.save!
    @working_draft = target
    render "update_draft"
  end

  def publish_draft
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    render "publish_draft"
  end

  def publish_version
    logger.info "Publish a draft tree"
    target = Tree::DraftVersion.find(params[:version_id])
    target.log_entry = params[:draft_log]
    response = target.publish(current_user.username, params[:next_draft_name])
    json = json(response)
    if json&.ok
      @message = "#### #{target.draft_name} published as #{target.tree.name} version #{target.id} ####"
      @message += "\nNew draft being created (it may take a couple of minutes to show up)." if json&.autocreate
      @working_draft = nil
      render "publish_version"
    else
      @message = json_result(response)
      render "publish_version_error"
    end
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "publish_version_error"
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "publish_version_error"
  end

  def reports
    @diff_link = Tree::AsServices.diff_link(@working_draft.tree.current_tree_version_id, @working_draft.id)
    @diff_link_raw = Tree::AsServices.diff_link(@working_draft.tree.current_tree_version_id, @working_draft.id).gsub(
      "embed=true", "embed=false"
    )
    @syn_link = Tree::AsServices.syn_link(@working_draft.tree.id)
    @syn_link_raw = Tree::AsServices.syn_link(@working_draft.tree.id).gsub("embed=true", "embed=false")
    @val_link = Tree::AsServices.val_link(@working_draft.id)
    @val_link_raw = Tree::AsServices.val_link(@working_draft.id).gsub("embed=true", "embed=false")
    @val_syn_link = Tree::AsServices.val_syn_link(@working_draft.id)
    @val_syn_link_raw = Tree::AsServices.val_syn_link(@working_draft.id).gsub("embed=true", "embed=false")
  end

  def update_synonymy
    logger.info "Update synonymy"
    Tree::AsServices.update_synonymy(request.raw_post, current_user.username)
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "update_synonymy_error"
  rescue RestClient::Exception => e
    @message = json_error(e)
    render "update_synonymy_error"
  end

  def update_synonymy_by_instance
    logger.info "Update synonymy by instance"
    Tree::AsServices.update_synonymy_by_instance(request.raw_post, current_user.username)
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "update_synonymy_error"
  rescue RestClient::Exception => e
    @message = json_error(e)
    render "update_synonymy_error"
  end

  # Move an existing taxon (inc children) under a different parent
  def replace_placement
    logger.info("In replace placement!")
    target = TreeVersionElement.find(move_name_params[:element_link])
    parent = TreeVersionElement.find(move_name_params[:parent_element_link])

    profile = Tree::ProfileData.new(current_user, target.tree_version, {})
    profile.update_comment(move_name_params[:comment])
    profile.update_distribution(move_name_params[:distribution])

    replacement = Tree::Workspace::Replacement.new(username: current_user.username,
                                                   target: target,
                                                   parent: parent,
                                                   instance_id: move_name_params[:instance_id],
                                                   excluded: move_name_params[:excluded],
                                                   profile: profile.profile_data)
    response = replacement.replace
    @html_out = process_problems(replacement_json_result(response))
    render "moved_placement"
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "move_placement_error"
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "move_placement_error"
  end

  # Place and instance on the draft tree version
  def place_name
    excluded = place_name_params[:excluded] ? true : false
    parent_element_link = place_name_params[:parent_name_typeahead_string].blank? ? nil : place_name_params[:parent_element_link]
    tree_version = TreeVersion.find(place_name_params[:version_id])

    profile = Tree::ProfileData.new(current_user, tree_version, {})
    profile.update_comment(place_name_params[:comment])
    profile.update_distribution(place_name_params[:distribution])

    placement = Tree::Workspace::Placement.new(username: current_user.username,
                                               parent_element_link: parent_element_link,
                                               instance_id: place_name_params[:instance_id],
                                               excluded: excluded,
                                               profile: profile.profile_data,
                                               version_id: place_name_params[:version_id])
    response = placement.place
    @message = placement_json_result(response)
    render "place_name"
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
    render "place_name_error"
  rescue RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "place_name_error"
  end

  def remove_name_placement
    target = TreeVersionElement.find(remove_name_placement_params[:taxon_uri])
    removement = Tree::Workspace::Removement.new(username: current_user.username,
                                                 target: target)
    response = removement.remove
    @message = json_result(response)
    render "removed_placement"
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    @message = json_error(e)
  end

  def update_comment
    logger.info "update comment #{update_comment_params[:element_link]} #{update_comment_params[:comment]}"
    tve = TreeVersionElement.find(update_comment_params[:element_link])
    profile_data = Tree::ProfileData.new(current_user, tve.tree_version, tve.tree_element.profile || {})
    profile_data.update_comment(update_comment_params[:comment])
    profile = Tree::Workspace::Profile.new(username: current_user.username,
                                           element_link: tve.element_link,
                                           profile_data: profile_data)
    profile.update
    render "update_comment"
  rescue RestClient::Unauthorized, RestClient::Forbidden, RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "update_comment_error"
  end

  def update_distribution
    logger.info "update distribution #{update_distribution_params[:element_link]} #{update_distribution_params[:dist]}"
    tve = TreeVersionElement.find(update_distribution_params[:element_link])
    dist = update_distribution_params[:dist]
    profile_data = Tree::ProfileData.new(current_user, tve.tree_version, tve.tree_element.profile || {})
    profile_data.update_distribution(dist)
    profile = Tree::Workspace::Profile.new(username: current_user.username,
                                           element_link: tve.element_link,
                                           profile_data: profile_data)
    profile.update
    render "update_distribution"
  rescue RestClient::Unauthorized, RestClient::Forbidden, RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "update_distribution_error"
  end

  def update_excluded
    logger.info "update excluded #{params[:taxonUri]} #{params[:excluded]}"
    Tree::Workspace::Excluded.new(username: current_user.username,
                                  element_link: params[:taxonUri],
                                  excluded: params[:excluded]).update
  rescue RestClient::Unauthorized, RestClient::Forbidden, RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render text: @message, status: 401
  end

  def update_tree_parent
    logger.info "update parent #{update_parent_params[:element_link]} parent #{update_parent_params[:parent_element_link]}"
    target = TreeVersionElement.find(update_parent_params[:element_link])
    parent = TreeVersionElement.find(update_parent_params[:parent_element_link])

    reparent = Tree::Workspace::Reparent.new(username: current_user.username,
                                             target: target,
                                             parent: parent)
    response = reparent.replace
    @html_out = process_problems(replacement_json_result(response))
    render "update_parent"
  rescue RestClient::Unauthorized, RestClient::Forbidden, RestClient::ExceptionWithResponse => e
    @message = json_error(e)
    render "update_parent_error"
  end

  def show_cas
    @val_syn_link = Tree::AsServices.val_syn_link(@working_draft.id)
  end

  # runs slowly...10 seconds maybe
  def run_cas
    url = Tree::AsServices.val_syn_link(@working_draft.id)
    @result = RestClient.get(url, { content_type: :html, accept: :html })
  rescue StandardError => e
    @message = e.to_s
    render "trees/reports/run_cas_error"
  end

  def show_diff
    @val_syn_link = Tree::AsServices.val_syn_link(@working_draft.id)
  end

  # may run slowly
  def run_diff
    url = Tree::AsServices.diff_link(@working_draft.tree.current_tree_version_id, @working_draft.id)
    @result = RestClient.get(url, { content_type: :html, accept: :html })
    return unless @result.match(/Nothing to see here.*no changes, nothing, zip/)

    @result = @result.sub(%r{<h3>Nothing to see here.</h3> *<p>We have no changes, nothing, zip.</p>},
                          "<h4>No changes.</h4>")
  end

  def show_valrep
    @val_link = Tree::AsServices.val_link(@working_draft.id)
  end

  # runs slowly...30 seconds maybe
  def run_valrep
    url = Tree::AsServices.val_link(@working_draft.id)
    @result = RestClient.get(url, { content_type: :html, accept: :html })
  end

  private

  def json_error(err)
    logger.error(err)
    json = JSON.parse(err.http_body, object_class: OpenStruct)
    if json&.error
      logger.error(json.error)
      json.error
    else
      "Tree Error: #{json&.to_s || err.to_s}"
    end
  rescue StandardError
    err.to_s
  end

  def json(result)
    JSON.parse(result.body, object_class: OpenStruct)
  end

  def json_payload(result)
    json = json(result)
    json&.payload
  end

  def json_result(result)
    json_payload(result)&.message || result.to_s
  rescue StandardError
    result.to_s
  end

  def get_version_from_response(result)
    payload = json_payload(result)
    TreeVersion.find(payload.versionNumber) if payload&.versionNumber
  end

  def placement_json_result(result)
    json_result(result)
  end

  def replacement_json_result(result)
    json_payload(result) || result.to_s
  end

  def process_problems(payload)
    payload["problems"]
  end

  def list_problems(key, problems)
    return "" if problems.nil? || problems.empty?

    "<strong>#{key}:</strong><ul><li>" +
      problems.join("</li><li>") +
      "</li></ul>"
  end

  def move_name_params
    params.require(:move_placement)
          .permit(:element_link,
                  :parent_element_link,
                  :instance_id,
                  :comment,
                  :excluded,
                  distribution: [])
  end

  def place_name_params
    params.require(:place_name)
          .permit(:name_id,
                  :instance_id,
                  :parent_element_link,
                  :comment,
                  :excluded,
                  :version_id,
                  :parent_name_typeahead_string,
                  :place,
                  distribution: [])
  end

  def update_comment_params
    params.require(:update_comment)
          .permit(:element_link,
                  :comment,
                  :update,
                  :delete)
  end

  def update_distribution_params
    params.require(:update_distribution)
          .permit(:element_link,
                  :distribution,
                  :update,
                  :delete,
                  dist: [])
  end

  def update_parent_params
    params.require(:update_parent)
          .permit(:element_link,
                  :parent_element_link,
                  :update,
                  :parent_name_typeahead_string)
  end

  def remove_name_placement_params
    params.require(:remove_placement).permit(:taxon_uri, :delete)
  end

  def find_tree
    @tree = Tree.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise "Could not find tree for id: #{params.id}"
  end
end
