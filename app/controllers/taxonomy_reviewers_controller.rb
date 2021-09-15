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
class TaxonomyReviewersController < ApplicationController
  before_action :find_taxonomy_reviewer,
                only: [:show, :destroy, :tab, :activate, :de_activate]

  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  def new
    @taxonomy_reviewer = TaxonomyReviewer.new
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def create
    @taxonomy_reviewer = TaxonomyReviewer.create(taxonomy_reviewer_params,
                                                 current_user.username)
    render "create.js"
  rescue => e
    logger.error("Controller:TaxonomyReviewers:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error.js", status: :unprocessable_entity
  end

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == 'true'
    render "show", layout: false
  end

  alias tab show

  def activate
    if @taxonomy_reviewer.active?
      throw 'Reviewer is already active'
    else 
      @taxonomy_reviewer.active = true
      @taxonomy_reviewer.save!
      render "activate.js"
    end
  rescue => e
    logger.error("Tree Reviewer activate rescuing #{e}")
    @message = e.to_s
    render "activate_error.js", status: :unprocessable_entity
  end

  def de_activate
    unless @taxonomy_reviewer.active?
      throw 'Reviewer is already active'
    else 
      @taxonomy_reviewer.active = false
      @taxonomy_reviewer.save!
      render "de_activate.js"
    end
  rescue => e
    logger.error("Tree Reviewer de_activate rescuing #{e}")
    @message = e.to_s
    render "de_activate_error.js", status: :unprocessable_entity
  end

  private

  def find_taxonomy_reviewer
    @taxonomy_reviewer = TaxonomyReviewer.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the taxonomy reviewer."
    redirect_to taxonomy_reviewers_path
  end

  def taxonomy_reviewer_params
    params.require(:taxonomy_reviewer).permit(:username, :organisation_name, :role_name, :active)
  end

  def set_tab
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             "tab_details"
           end
  end

  def set_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end
end
