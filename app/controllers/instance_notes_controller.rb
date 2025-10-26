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
class InstanceNotesController < ApplicationController
  before_action :set_instance_note, only: %i[show edit update destroy]

  # GET /instance_notes/1
  # GET /instance_notes/1.json
  def show; end

  # GET /instance_notes/new
  def new
    @instance_note = InstanceNote.new
  end

  # GET /instance_notes/1/edit
  def edit
    render "edit"
  end

  # POST /instance_notes
  # POST /instance_notes.json
  def create
    if InstanceNote.new(instance_note_params)
                   .save_with_username(current_user.username)
      @message = "Saved"
      render :create
    else
      raise("Not saved")
    end
  rescue StandardError => e
    @message = e.to_s
    render "create_failed", status: :unprocessable_content
  end

  # PATCH/PUT /instance_notes/1
  # PATCH/PUT /instance_notes/1.json
  def update
    @message = "No change"
    really_update if changed?
  end

  # DELETE /instance_notes/1
  # DELETE /instance_notes/1.json
  def destroy
    @instance_note.updated_by = current_user.username
    if @instance_note.save(validate: false) && @instance_note.destroy
      render :destroy
    else
      @message = "Could not delete that record."
      render "update_failed", status: :unprocessable_content
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_instance_note
    @instance_note = InstanceNote.find(params[:id])
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  def instance_note_params
    params.require(:instance_note).permit(:instance_id,
                                          :instance_note_key_id,
                                          :value,
                                          :sort_order)
  end

  def changed?
    @instance_note.instance_note_key_id.to_s != \
      instance_note_params[:instance_note_key_id] ||
      @instance_note.value != instance_note_params[:value]
  end

  def really_update
    if @instance_note.update_attributes_with_username!(instance_note_params,
                                                       current_user.username)
      @message = "Updated"
      render :update
    else
      raise("Not updated")
    end
  rescue StandardError => e
    @message = e.to_s
    render :update_failed, status: :unprocessable_content
  end
end
