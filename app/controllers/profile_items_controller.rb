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
class ProfileItemsController < ApplicationController
  before_action :set_profile_item, only: %i[destroy]

  def destroy
    @product_item_config = @profile_item.product_item_config
    @instance_id = @profile_item.instance_id
    if @profile_item.destroy!
      @message = "Deleted profile item."
    else
      raise("Not saved")
    end
  rescue StandardError => e
    @message = "Error deleting profile item: #{e.message}"
    render "destroy_failed", status: :unprocessable_entity
  end

  private

  def set_profile_item
    @profile_item = Profile::ProfileItem.find(params[:id])
  end
end