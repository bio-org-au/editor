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
class Loader::Batch::Review::ModeController < ApplicationController

  def switch_on
    session[:view_mode_set_by_user] = true
    @view_mode = session[:view_mode] = ::ViewMode::REVIEW
    render :switch_on, layout: false
  end

  def switch_off
    session[:view_mode_set_by_user] = false
    @view_mode = session[:view_mode] = ::ViewMode::STANDARD
    render :switch_off, layout: false
  end
end
