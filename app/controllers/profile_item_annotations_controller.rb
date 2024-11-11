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
class ProfileItemAnnotationsController < ApplicationController
  before_action :set_profile_item_annotation, only: %i[update]

  def create
    # Check for existing ProfileAnnotation based on profile_item_id
    @profile_item_annotation = Profile::ProfileItemAnnotation.new(
      permitted_params.merge(
        created_by: current_user.username,
        updated_by: current_user.username
      )
    )
    if @profile_item_annotation.save!
      @message = "Saved"
      render :create
    end
  rescue StandardError => e
    @message = e.to_s
    render "create_failed", status: :unprocessable_entity
  end

  def update
    @message = "No change"
    really_update if changed?
  end

  private

  def set_profile_item_annotation
    @profile_item_annotation = Profile::ProfileItemAnnotation.find(params[:id])
  end

  def changed?
    @profile_item_annotation.value != permitted_params[:value]
  end

  def really_update
    if @profile_item_annotation.update(permitted_params.merge(updated_by: current_user.username))
      @message = "Updated"
      render :update
    else
      raise("Not updated")
    end
  rescue StandardError => e
    @message = e.to_s
    render :update_failed, status: :unprocessable_entity
  end

  def permitted_params
    params.require(:profile_item_annotation).permit(:profile_item_id, :value)
  end
end
