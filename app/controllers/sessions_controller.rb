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
class SessionsController < ApplicationController

  def new
    build_sign_in
  end

  def retry_new
    build_sign_in
    @sign_in.errors[:base] << "Please retry.  There was a system problem."
    render "new"
  end

  # Known problem: if login is rejected due to no login authority
  # entering a legit username/password into the re-rendered sign in form
  # fails the first time.
  def create
    build_sign_in
    if @sign_in.save && authorised_to_login?
      set_up_session
      deep_link || (redirect_to :root)
    else
      render "new", status: :unprocessable_entity
    end
  rescue StandardError => e
    logger.error("Exception signing in: #{e.to_s.gsub(/password:[^,]*/, 'password: [filtered]')}")
    redirect_to :retry_start_sign_in
  end

  def destroy
    reset_session
    redirect_to :start_sign_in
  end

  # For testing.
  def throw_invalid_authenticity_token
    raise ActionController::InvalidAuthenticityToken
  end

  private

  def build_sign_in
    # Do we need to reset the session? For security?
    # deep_link = session[:url_after_sign_in]
    # reset_session
    # session[:url_after_sign_in] = deep_link
    @sign_in = SignIn.new(sign_in_params)
    @no_searchbar = true
    @no_search_result_details = true
    @no_advanced_search = true
    @no_menus = true
  end

  def set_up_session
    session[:username] = sign_in_params[:username]
    session[:groups] = @sign_in.groups
    session[:user_full_name] = @sign_in.user_full_name
    session[:user_cn] = @sign_in.user_cn
    session[:generic_active_directory_user] = @sign_in.generic_active_directory_user
    session[:include_common_and_cultivar] = false
    session[:workspace] = {}
  end

  def deep_link
    if session[:url_after_sign_in].present?
      url_after_sign_in = session[:url_after_sign_in]
      session[:url_after_sign_in] = ""
      redirect_to url_after_sign_in
    else
      false
    end
  end

  def sign_in_params
    sign_in_params = params[:sign_in]
    sign_in_params&.permit(:username, :password)
  end

  def authorised_to_login?
    if @sign_in.groups.include?('login')
      true
    else
      @sign_in.make_invalid # simulate failed credentials
      reset_session
      false
    end
  end
end
