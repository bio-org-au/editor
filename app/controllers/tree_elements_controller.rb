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
class TreeElementsController < ApplicationController
  before_action :find_tree_element, only: [:show, :tab, :update_profile]

  # GET /tree_vesions/1
  # GET /tree_vesions/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    @tab = choose_tab
    @tab_index = choose_index
    @take_focus = params[:take_focus] == 'true'
    @tree_version = TreeVersion.find(params['tree-version-id'])
    logger.debug("params: #{params.inspect}")
    render "show", layout: false
  end

  alias tab show

  def update_profile
    @refresh = false
    @message = 'No change'
    update_distribution if tree_element_params[:distribution_value].present?
    update_comment if tree_element_params[:comment_value].present?
  rescue => e
    logger.error("TreeElementsController:update_profile:rescuing exception #{e}")
    @message = "Update error: #{e}"
    render :update_profile_error, status: :unprocessable_entity
  end

  private

  def update_distribution
    new_cleaned = TreeElement.cleanup_distribution_string(tree_element_params[:distribution_value])
    TreeElement.validate_distribution_string(new_cleaned)
    unless @tree_element.distribution_value == new_cleaned
      @message = 'Distribution changed'
      @refresh = true
      @tree_element.update_distribution_directly(new_cleaned, @current_user.username)
      te = TreeElement.find(@tree_element.id)
      te.apply_string_to_tedes
    end
  end

  def update_comment
    unless @tree_element.comment_value == tree_element_params[:comment_value]
      @message = 'Comment changed'
      @refresh = true
      @tree_element.update_comment_directly(tree_element_params[:comment_value], @current_user.username)
    end
  end

  def find_tree_element
    @tree_element = TreeElement.find(params[:id])
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
