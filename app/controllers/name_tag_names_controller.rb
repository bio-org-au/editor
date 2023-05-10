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
  before_action :set_name_tag_name, only: [:show, :edit, :update, :destroy]

  # GET /name_tag_names/1
  # GET /name_tag_names/1.json
  def show
  end

  # GET /name_tag_names/new
  def new
    @name_tag_name = NameTagName.new
  end

  # POST /name_tag_names
  # POST /name_tag_names.json
  # Short-time work-around.
  #
  # There is a problem with the AR create for composite keys
  # under JRuby 9k (9.1.2.0, 9.1.5.0 are the versions I know about).
  # The "returning" clause of the insert is generated as "name_id, tag_id",
  # which is invalid sql.  Under Matz' ruby the "returning" clause is
  # "name_id", "tag_id" which works.
  def build_insert
    "INSERT INTO name_tag_name (name_id, tag_id, created_at, created_by,
    updated_at, updated_by) VALUES (#{name_tag_name_params[:name_id]},
    #{name_tag_name_params[:tag_id]}, current_timestamp,
    '#{current_user.username}', current_timestamp, '#{current_user.username}')
    returning name_id, tag_id"
  end
  private :build_insert

  def create
    ActiveRecord::Base.connection.execute(build_insert)
    @name_tag_name = NameTagName.find([name_tag_name_params[:name_id],
                                       name_tag_name_params[:tag_id]])
    @message = ""
    render :create, format: :js
  rescue => e
    logger.error("Name Tag Name create failed: #{e}")
    @message = "Could not attach that tag because #{e}"
    render :create_failed, format: :js, status: :unprocessable_entity
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
