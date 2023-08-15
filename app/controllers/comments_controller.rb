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
class CommentsController < ApplicationController
  # All text/html requests should go to the search page.
  before_action :javascript_only
  before_action :set_comment, only: %i[show edit update destroy]

  # GET /comments/1
  # GET /comments/1.json
  def show; end

  # POST /comments
  # POST /comments.json
  def create
    @message = ""
    @comment = Comment.new(comment_params)
    respond_to do |format|
      if @comment.save_with_username(current_user.username)
        format.js {}
      else
        @message = "Not saved: #{@comment.errors.full_messages.first}"
        format.js { render :create_failed }
      end
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update
    @message = "No change"
    really_update unless @comment.text.to_s == comment_params[:text].strip
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  # This was being called in the last controller test I got working for rails6.
  # I had to hack it a bit and it certainly needs more looking at, but
  # the check for a javascript request seemed not important enough to delay for.
  def destroy
    throw "request must be js" unless request.format == "text/javascript" || request.format == "application/json"
    username = current_user.username
    if @comment.update(updated_by: username) && @comment.destroy
      respond_to do |format|
        format.html { redirect_to comments_url, notice: "Comment deleted." }
        format.json { head :no_content }
        format.js {}
      end
    else
      throw "There was a problem deleting that record."
    end
  rescue StandardError => e
    @message = e.to_s
    render "destroy_failed", status: 503
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  def comment_params
    params.require(:comment).permit(:instance_id,
                                    :author_id,
                                    :reference_id,
                                    :name_id,
                                    :text)
  end

  def really_update
    if @comment.update_attributes_with_username(comment_params,
                                                current_user.username)
      @message = "Updated"
      render :update
    else
      @message = "Not saved. #{@comment.errors.full_messages.first}"
      render :update_failed
    end
  end
end
