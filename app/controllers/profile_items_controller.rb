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

  skip_before_action :authorise

  before_action :set_profile_item, only: %i[show tab destroy details]
  before_action :authorise_user!, except: %i[tab index details]

  # GET /profile_items/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    pick_a_tab
    pick_a_tab_index
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  def details
    @selected_instance = Instance.find_by(id: params[:instance_id])
    respond_to do |format|
      format.turbo_stream
    end
  end

  alias tab show

  def destroy
    @profile_item_id = @profile_item.id
    @product_item_config = @profile_item.product_item_config
    @instance_id = @profile_item.instance_id
    if @profile_item.destroy
      @message = "Deleted profile item."
    else
      raise("Not saved: #{@profile_item.errors.full_messages.to_sentence}")
    end
  rescue StandardError => e
    @message = "Error deleting profile item: #{e.message}"
    render "destroy_failed", status: :unprocessable_content
  end

  def index
    @instance = Instance.find_by!(id: permitted_profile_item_params[:instance_id])
    @product_configs_and_profile_items, _product = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs
      .new(
        @current_user,
        @instance,
        permitted_profile_item_params
      ).run_query
  end

  private

  def authorise_user!
    raise CanCan::AccessDenied.new("Access Denied!", :manage, @profile_item) unless can? :manage, @profile_item
  end

  def set_profile_item
    @profile_item = Profile::ProfileItem.find(params[:id])
  end

  def permitted_profile_item_params
    params.permit(:instance_id, :product_item_config_id)
  end

end
