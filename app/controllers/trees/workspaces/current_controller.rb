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

#   User can choose a workspace.
class Trees::Workspaces::CurrentController < ApplicationController
  def toggle
    if session[:draft] &&
       session[:draft]["id"] == params[:id].to_i
      unset_workspace
    else
      set_workspace
    end
  end

  private

  # Set instance variable for use in the request.
  # Set session variable for following requests.
  # Need both because session variable loses ActiveRecord features
  # but activerecord variable dies after the request.
  def set_workspace
    @working_draft = TreeVersion.find(params[:id])
    session[:draft] = @working_draft
  end

  def unset_workspace
    remove_instance_variable(:@working_draft)
    session[:draft] = nil
  end
end
