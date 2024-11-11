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
class Loader::Name::Review::VotesController < ApplicationController
  before_action :find_vote, only: %i[destroy]

  def create
    @review_vote = Loader::Name::Review::Vote.new(review_vote_params)
    @review_vote.save_with_username(current_user.username)
    render "create"
    rescue => e
      logger.error("Loader::Name::Review::Vote.create:rescuing exception #{e}")
      @error = e.to_s
      render "create_error", status: :unprocessable_entity
  end

  def destroy
    username = @current_user.username
    if @vote.update_attribute(:updated_by, username) && @vote.destroy
      render
    else
      render js: "alert('Could not delete .');"
    end
  end

  private

  def review_vote_params
    params.require(:loader_name_review_vote).permit(:id,
                                                    :loader_name_id,
                                                    :batch_review_id,
                                                    :batch_reviewer_id,
                                                    :org_id,
                                                    :vote
                                                    )
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

  def find_vote
    @vote = Loader::Name::Review::Vote.find(params[:id])
  end
end
