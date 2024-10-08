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
class ProfileTextsController < ApplicationController
  before_action :set_profile_text, only: %i[show edit update destroy]

  # GET /profile_texts/1
  # GET /profile_texts/1.json
  def show; end

  # GET /profile_texts/new
  def new
    @profile_text = Profile::ProfileText.new
  end

  # GET /profile_texts/1/edit
  def edit
    render "edit"
  end

  # POST /profile_texts
  # POST /profile_texts.json
  def create
    permitted_profile_text_params = params.require(:profile_text).permit(:value)
    permitted_profile_item_params = params.require(:profile_item).permit(:id, :instance_id, :product_item_config_id, :profile_object_rdf_id)
    
    product_item_config = Profile::ProductItemConfig.find(permitted_profile_item_params[:product_item_config_id])
    @profile_item = Profile::ProfileItem.find_or_create_by(permitted_profile_item_params)
    @profile_item.tap do |pi|
      pi.created_by = current_user.username
      pi.updated_by = current_user.username
    end
    @profile_text = @profile_item.build_profile_text(
      value: permitted_profile_text_params[:value],
      value_md: permitted_profile_text_params[:value],
      created_by: current_user.username,
      updated_by: current_user.username
    )

    if @profile_text.persisted?
      raise("Profile text already exists")
    elsif @profile_item.save! && @profile_text.save!
      @message = "Saved"
      render :create
    end
  rescue StandardError => e
    @message = e.to_s
    render "create_failed", status: :unprocessable_entity
  end
  

  # PATCH/PUT /profile_texts/1
  # PATCH/PUT /profile_texts/1.json
  def update
    debugger
    @message = "No change"
    really_update if changed?
  end

  # DELETE /profile_texts/1
  # DELETE /profile_texts/1.json
  def destroy
    if @profile_text.destroy
      render :destroy
    else
      @message = "Could not delete that record."
      render "update_failed", status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_profile_text
    @profile_text = Profile::ProfileText.find(params[:id])
  end

  # only allow the white list through.
  def profile_text_params
    params.require(:profile_text).permit(:value)
  end

  def changed?
    @profile_text.value != profile_text_params[:value]
  end

  def really_update
    if @profile_text.update(profile_text_params)
      @message = "Updated"
      render :update
    else
      raise("Not updated")
    end
  rescue StandardError => e
    @message = e.to_s
    render :update_failed, status: :unprocessable_entity
  end
end
