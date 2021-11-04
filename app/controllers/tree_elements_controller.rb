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
  before_action :find_tree_element, only: [:show, :tab]

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

  private

  def find_tree_element
    @tree_element = TreeElement.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the tree element."
    redirect_to tree_elements_path
  end

  def tree_element_params
    params.require(:tree_element).permit(:draft_name)
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
