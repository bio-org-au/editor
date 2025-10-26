
# frozen_string_literal: true

#   Copyright 2024 Australian National Botanic Gardens
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
class Loader::Name::Review::Vote::InBulkController < ApplicationController

  def create
    result = Loader::Name::Review::Vote.in_bulk(review_vote_in_bulk_params, current_user.username)
    @message = ActionController::Base.helpers.pluralize(result, 'vote') + ' recorded'
    render "create"
  rescue => e
    logger.error("Loader::Name::Review::Vote::InBulk.create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_content
  end

  def destroy
    throw 'stop'
    username = @current_user.username
    if @vote.update_attribute(:updated_by, username) && @vote.destroy
      render
    else
      render js: "alert('Could not delete .');"
    end
  end

  private

  def review_vote_in_bulk_params
    params.require(:loader_name_review_vote).permit(:id,
                                                    :loader_name_id,
                                                    :batch_review_id,
                                                    :org_id,
                                                    :vote
                                                    )
  end
end
