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
class ProfileItemReferencesController < ApplicationController
  skip_before_action :authorise

  before_action :set_profile_item_reference, only: %i[update destroy]

  before_action :authorise_user!, except: [:create]

  def create
    @profile_item_reference = Profile::ProfileItemReference.new(
      permitted_params.merge(
        created_by: current_user.username,
        updated_by: current_user.username
      )
    )

    authorise_user!

    if @profile_item_reference.save!
      @message = "Saved"
      render :create
    end

  rescue StandardError => e
    @message = "Error creating profile item reference: #{e.message}"
    render "create_failed", status: :unprocessable_entity
  end

  def update
    @message = "No change"
    really_update if changed?
  end

  def destroy
    @profile_item = @profile_item_reference.profile_item
    if @profile_item_reference.destroy!
      @message = "Deleted profile item reference."
    else
      raise("Not deleted")
    end
  rescue StandardError => e
    @message = "Error deleting profile item reference: #{e.message}"
    render "destroy_failed", status: :unprocessable_entity
  end

  private

  def authorise_user!
    raise CanCan::AccessDenied.new("Access Denied!", :manage, @profile_item_reference) unless can? :manage, @profile_item_reference
  end

  def set_profile_item_reference
    @profile_item_reference = Profile::ProfileItemReference.find_by(profile_item_id: params[:profile_item_id], reference_id: params[:reference_id])
  end

  def changed?
    @profile_item_reference.annotation != permitted_params[:annotation]
  end

  def really_update
    if @profile_item_reference.update(permitted_params.merge(updated_by: current_user.username))
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
    params.require(:profile_item_reference).permit(:reference_id, :annotation, :profile_item_id)
  end
end
