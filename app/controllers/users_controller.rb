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
class UsersController < ApplicationController
  before_action :find_user, only: %i[show tab update destroy]

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @user = User.new if params[:tab] == "tab_periods"
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  alias tab show

  # GET /user/new_row
  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    render :new_row, 
       locals: {partial: 'new_row', 
                locals_for_partial:
                  {tab_path: "#{new_user_with_random_id_path(@random_id)}",
                   link_id: "link-new-user-#{@random_id}",
                   link_title: "New User",
                   link_text: "New User"
                  }
               }
  end

  # GET /users/new
  def new
    @user = User.new
    @no_search_result_details = true
    @tab_index = (params[:tabIndex] || "40").to_i
    render :new
  end

  # POST /users
  def create
    @user = User.create(user_params, current_user.username)
    render "create"
  rescue StandardError => e
    logger.error("UserController.create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_entity
  end

  # POST /users
  def update
    @message = @user.update_if_changed(user_params, current_user.username)
    render "update"
  rescue => e
    logger.error("Review.update:rescuing exception #{e}")
    @error = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  def destroy
    @user.destroy
  end

  private

  def find_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the user record."
    redirect_to user_path
  end

  def user_params
    params.require(:user).permit(:id, :user_name, :given_name, :family_name)
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
