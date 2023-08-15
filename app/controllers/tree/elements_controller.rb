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
class Tree::ElementsController < ApplicationController
  before_action :find_tree_element, only: %i[show tab update_profile]

  # GET /tree_vesions/1
  # GET /tree_vesions/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    @tab = choose_tab
    @tab_index = choose_index
    @take_focus = params[:take_focus] == "true"
    @tree_version = TreeVersion.find(params["tree-version-id"])
    render "show", layout: false
  end

  alias tab show

  # Update a mini schema of data with optional fields in a jsonb structure.
  # This process is messy - jsonb not a good choice for data that changes imo.
  # Note: this code is separate from the tree controller code for
  # setting up profile data in a tree draft via services.  This code was added
  # later to allow editing of profile data in a way that does not involve
  # a new version of the taxonomy i.e. CRUD directly into the database.
  def update_profile
    scope = "Distribution"
    @distribution_message, dist_refresh = @tree_element.update_distribution(
      tree_element_params[:distribution_value], @current_user.username
    )
    scope = "Comment"
    # After working on distribution part of the schema
    # start with a fresh record from the database to work on the
    # comment part of the schema
    find_tree_element # Pick up refreshed data from database to avoid overwrite
    @comment_message, comment_refresh = @tree_element.update_comment(
      tree_element_params[:comment_value].gsub(/\n/, " ").strip,
      @current_user.username
    )
    @refresh = dist_refresh || comment_refresh
  rescue StandardError => e
    logger.error("Tree::ElementsController:update_profile:rescuing #{scope} exception #{e}")
    @message = "#{scope} update error: #{e}"
    render :update_profile_error, status: :unprocessable_entity
  end

  private

  def find_tree_element
    @tree_element = Tree::Element.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the tree element."
    redirect_to tree_elements_path
  end

  def tree_element_params
    params.require(:tree_element).permit(:draft_name, :distribution_value,
                                         :comment_value)
  end

  def choose_tab
    if params[:tab].present? && params[:tab] != "undefined"
      params[:tab]
    else
      "tab_details"
    end
  end

  def choose_index
    (params[:tabIndex] || "1").to_i
  end
end
