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
class Loader::Name::Review::CommentsController < ApplicationController
  before_action :find_comment, only: [:show, :destroy, :tab]

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == 'true'
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
    logger.debug(review_comment_params.inspect)
    @review_comment = Loader::Name::Review::Comment.new(review_comment_params)
    logger.debug('before save')
    @review_comment.save_with_username(current_user.username)
    logger.debug('after save')
    render "create"
  rescue => e
    logger.error("Loader::Name::Review::Comment.create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_entity
  end

  private

  def find_comment
    #@loader_batch = Loader::Batch.find(params[:id])
  #rescue ActiveRecord::RecordNotFound
    #flash[:alert] = "We could not find the loader batch record."
    #redirect_to loader_batches_path
  end

  def review_comment_params
    params.require(:loader_name_review_comment).permit(:loader_name_id,
                                                       :review_period_id,
                                                       :batch_reviewer_id,
                                                       :comment)
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
