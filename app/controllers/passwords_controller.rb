# frozen_string_literal: true

#   Copyright 2019 Australian National Botanic Gardens
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
# Administrator Actions
class PasswordsController < ApplicationController
  before_action :hide_details, :empty_search

  def edit
    @password = Password.new
  end

  def update
    Rails.logger.debug("Now in change_password")
    @password = Password.new
    @password.current_password = params[:password]["current_password"]
    @password.new_password = params[:password]["new_password"]
    @password.new_password_confirmation = params[:password]["new_password_confirmation"]
    @password.username = @current_user.username
    @password.user_cn = session[:user_cn]
    if @password.save!
      render :updated
    else
      render :edit
    end
  rescue => e
    render :edit
  end
end

