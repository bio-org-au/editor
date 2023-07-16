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
class ServicesController < ApplicationController
  skip_before_action :authenticate

  def index
    render layout: "services"
  end

  def ping
    render plain: "✓", status: :ok, layout: false
  end

  def version
    render plain: "#{Rails.configuration.try('version')}",
           status: :ok,
           layout: false
  end

  def build
    render partial: 'build',
           format: :text,
           status: :ok,
           layout: false
  end

  def clear_connections
    ActiveRecord::Base.clear_active_connections!
    render plain: "Cleared.", status: :ok, layout: false
  end
end
