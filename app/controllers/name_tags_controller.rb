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
class NameTagsController < ApplicationController
  before_action :set_name_tag, only: %i[show edit update destroy]

  # GET /name_tags/1
  # GET /name_tags/1.json
  def show; end

  # GET /name_tags/new
  def new
    @name_tag = NameTag.new
  end

  # POST /name_tags
  # POST /name_tags.json
  def create
    @name_tag = NameTag.new(name_tag_params)
    respond_to do |format|
      if @name_tag.save
        format.html { redirect_to @name_tag, notice: "Created." }
        format.json { render :show, status: :created, location: @name_tag }
      else
        format.html { render :new }
        format.json do
          render json: @name_tag.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /name_tags/1
  # DELETE /name_tags/1.json
  def destroy
    @name_tag.destroy
    respond_to do |format|
      format.html { redirect_to name_tags_url, notice: "Deleted." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_name_tag
    @name_tag = NameTag.find(params[:id])
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  def name_tag_params
    params.require(:name_tag).permit(:name)
  end
end
