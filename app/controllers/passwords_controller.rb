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
    if session[:generic_active_directory_user]
      render :edit_error
    else
      edit_inner
    end
  rescue StandardError => e
    logger.error("Password change error: #{e}")
    render :edit_error
  end

  def update
    if session[:generic_active_directory_user]
      render :edit_error
    else
      update_inner
    end
  end

  def show_password_form
    @password = Password.new
  end

  private

  def edit_inner
    @password = Password.new
    redirect_to action: :show_password_form
  end

  def update_inner
    @password = Password.new
    @password.current_password = params[:password]["current_password"]
    @password.new_password = params[:password]["new_password"]
    @password.new_password_confirmation = params[:password]["new_password_confirmation"]
    @password.username = @current_user.username
    @password.user_cn = session[:user_cn]
    if @password.save!
      redirect_to :password_changed
    else
      render :show_password_form, status: :unprocessable_content
    end
  rescue StandardError => e
    Rails.logger.error(e.to_s)
    render :show_password_form, status: :unprocessable_content
  end
end
