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
class Loader::Batch::ReviewersController < ApplicationController
  before_action :find_batch_reviewer, only: %i[show destroy tab]

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @batch_reviewer = Loader::Batch::Reviewer.new if params[:tab] == "tab_reviewers"
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  alias tab show

  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  def create
    @batch_reviewer = ::Loader::Batch::Reviewer.create(batch_reviewer_params,
                                                       current_user.username)
    render "create"
  rescue StandardError => e
    logger.error("Controller:Loader::Batch::ReviewersController#create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_content
  end

  def destroy
    @batch_reviewer.destroy
  end

  private

  def find_batch_reviewer
    @batch_reviewer = Loader::Batch::Reviewer.find(params[:id] || batch_reviewer_params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the batch reviewer record."
    redirect_to batch_reviewers_path
  end

  def batch_reviewer_params
    params.require(:loader_batch_reviewer).permit(:id, :name, :batch_review_id, :user_id, :org_id,
                                                  :batch_review_role_id)
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
