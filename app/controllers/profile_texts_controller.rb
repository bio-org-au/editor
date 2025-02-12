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
  include ApplicationHelper
  
  before_action :set_profile_text, :find_profile_item, only: %i[update]

  # POST /profile_texts
  # POST /profile_texts.json
  def create
    @profile_item = Profile::ProfileItem.find_or_create_by(permitted_profile_item_params)

    raise("Profile text already exists") unless @profile_item.new_record?

    @profile_item.tap do |pi|
      pi.created_by = current_user.username
      pi.updated_by = current_user.username
    end

    @profile_text = @profile_item.build_profile_text(
      value: markdown_to_html(permitted_profile_text_params[:value_md].to_s),
      value_md: permitted_profile_text_params[:value_md],
      created_by: current_user.username,
      updated_by: current_user.username
    )

    if @profile_text.persisted?
      raise("Profile text already exists")
    elsif @profile_text.save! && @profile_item.save!
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
    @message = "No change"
    really_update if changed?
  end

  private

  def permitted_profile_text_params
    params.require(:profile_text).permit(:value, :value_md)
  end

  def permitted_profile_item_params
    params.require(:profile_item).permit(:id, :instance_id, :product_item_config_id, :profile_object_rdf_id)
  end

  def find_profile_item
    @profile_item = Profile::ProfileItem.find(params[:profile_item][:id])
  end

  def set_profile_text
    @profile_text = Profile::ProfileText.find(params[:id])
  end

  def changed?
    @profile_text.value_md != permitted_profile_text_params[:value_md]
  end

  def really_update
    if @profile_text.update(permitted_profile_text_params.merge(updated_by: current_user.username))
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
