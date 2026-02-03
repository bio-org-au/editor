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
class Names::NameResourcesController < ApplicationController
  before_action :find_name

  def create
    @name_resource = @name.name_resources.new(permitted_params)
    @name_resource.current_user = current_user

    if @name_resource.save
      @message = "Saved"
      render :create
    else
      @message = @name_resource.errors.full_messages.join(",")
      Rails.logger.error "Failed to create NameResource: #{@message}"
      render "create_failed", status: :unprocessable_content
    end
  end

  def update
    @message = "No change"

    @name_resource = @name.name_resources.find(params[:id])
    @name_resource.assign_attributes(permitted_params)

    render :update and return unless @name_resource.changed?

    @name_resource.current_user = current_user

    if @name_resource.save
      @message = "Updated"
      render :update
    else
      @message = @name_resource.errors.full_messages.join(",")
      Rails.logger.error "Failed to update NameResource: #{@message}"
      render "update_failed", status: :unprocessable_content
    end
  end

  def destroy
    @name_resource = @name.name_resources.find(params[:id])
    if @name_resource.destroy
      @message = "Deleted"
      render :destroy
    else
      @message = @name_resource.errors.full_messages.join(",")
      Rails.logger.error "Failed to delete NameResource: #{@message}"
      render "destroy_failed", status: :unprocessable_content
    end
  end

  private

  def find_name
    @name = Name.find(params[:name_id])
    if @name.nil?
      render plain: "Name not found", status: :not_found
    end
  end

  def permitted_params
    params
      .require(:name_resource)
      .permit(
        :resource_host_id,
        :value,
        :note
      )
  end
end
