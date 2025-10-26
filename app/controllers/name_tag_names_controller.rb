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
class NameTagNamesController < ApplicationController
  before_action :set_name_tag_name, only: %i[show edit destroy]

  # GET /name_tag_names/1
  # GET /name_tag_names/1.json
  def show; end

  # GET /name_tag_names/new
  def new
    @name_tag_name = NameTagName.new
  end

  # POST /name_tag_names
  # POST /name_tag_names.json
  def create
    @name_tag_name = NameTagName.new(name_tag_name_params)
    @name_tag_name.save_new_record_with_username(current_user.username)
  rescue StandardError => e
    logger.error("Name Tag Name create failed: #{e}")
    @message = "Could not attach that tag because #{e}"
    render :create_failed, format: :js, status: :unprocessable_content
  end

  # DELETE /name_tag_names/1
  # DELETE /name_tag_names/1.json
  def destroy
    @name_tag_name.destroy
    respond_to do |format|
      format.html { redirect_to name_tag_names_url, notice: "Deleted." }
      format.json { head :no_content }
      format.js   {}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_name_tag_name
    @name_tag_name = NameTagName
                     .where(name_id: params[:name_id])
                     .where(tag_id: params[:tag_id]).first
  end

  # White list
  def name_tag_name_params
    params.require(:name_tag_name).permit(:name_id, :tag_id)
  end
end
