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
  skip_before_action :authorise

  before_action :set_profile_item_annotation, only: %i[update]

  before_action :authorise_user!, except: [:create]

  def create
    # Check for existing ProfileAnnotation based on profile_item_id
    @profile_item_annotation = Profile::ProfileItemAnnotation.new(
      permitted_params.merge(
        created_by: current_user.username,
        updated_by: current_user.username
      )
    )

    authorise_user!

    if @profile_item_annotation.save!
      @message = "Saved"
      render :create
    end
  rescue StandardError => e
    @message = e.to_s
    render "create_failed", status: :unprocessable_content
  end

  def update
    @message = "No change"
    @profile_item = @profile_item_annotation.profile_item
    really_update if changed?
  end

  private

  def authorise_user!
    raise CanCan::AccessDenied.new("Access Denied!", :manage, @profile_item_annotation) unless can? :manage, @profile_item_annotation
  end

  def set_profile_item_annotation
    @profile_item_annotation = Profile::ProfileItemAnnotation.find(params[:id])
  end

  def changed?
    @profile_item_annotation.value != permitted_params[:value]
  end

  def really_update
    if permitted_params[:value].blank?
      @profile_item_annotation.destroy!
      @message = "Deleted"
      render :delete
    elsif @profile_item_annotation.update(permitted_params.merge(updated_by: current_user.username))
      @message = "Updated"
      render :update
    else
      raise("Not updated")
    end
  rescue StandardError => e
    @message = e.to_s
    render :update_failed, status: :unprocessable_content
  end

  def permitted_params
    params.require(:profile_item_annotation).permit(:profile_item_id, :value)
  end
end
