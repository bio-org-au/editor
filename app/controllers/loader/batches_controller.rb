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
class Loader::BatchesController < ApplicationController
  include Loader::Batches::MultiplySeqs
  include Loader::Batches::RefreshSortKey
  before_action :find_loader_batch,
                only: %i[show destroy tab update multiply_seqs_by_10
                         refresh_syn_sort_keys]
  def index; end

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == "true"
    if params[:tab] == "tab_batch_review"
      @batch_review = Loader::Batch::Review.new
      @batch_review.loader_batch_id = @loader_batch.id
    end
    render "show", layout: false
  end
  alias tab show

  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    render :new_row, 
           locals: {partial: 'new_row', 
                    locals_for_partial:
               {tab_path: "#{loader_batch_new_with_random_id_path(@random_id)}",
                link_id: "link-new-loader-batch-#{@random_id}",
                link_title: "New Loader Batch",
                link_text: "New Loader Batch"
               }
                   }
  end

  def new
    @anchor = Loader::Name.find(params[:loader_batch_id]) unless params[:loader_batch_id].blank?
    @loader_batch = ::Loader::Batch.new
    @tab_index = (params[:tabIndex] || "40").to_i
    render :new
  end

  def create
    raise 'Not authorised' unless @current_user.batch_loader?
    @loader_batch = Loader::Batch.create(loader_batch_params,
                                      current_user.username)
    render "create"
  rescue StandardError => e
    logger.error("Controller:Loader:Batches:create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error", status: :unprocessable_entity
  end

  def update
    raise 'Not authorised' unless @current_user.batch_loader?
    @message = @loader_batch.update_if_changed(loader_batch_params,
                                               current_user.username)
    render "update"
  rescue StandardError => e
    logger.error("Loader::Batches#update rescuing #{e}")
    @message = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  def destroy
    raise 'Not authorised' unless @current_user.batch_loader?
    @loader_batch.delete
  rescue StandardError => e
    logger.error("Loader::BatchesController#destroy rescuing #{e}")
    @message = e.to_s
    render "destroy_error", status: :unprocessable_entity
  end

  def make_default
    find_loader_batch
    session[:default_loader_batch_id] = params[:id]
    session[:default_loader_batch_name] = @loader_batch.name
    @message = "Done"
    @from_menu = params[:from] == 'from-menu' ? true : false
  end

  def clear_default
    session[:default_loader_batch_id] = nil
    session[:default_loader_batch_name] = nil
    @from_menu = params[:from] == 'from-menu' ? true : false
    @message = "Done"
  end

  def stats
    @stats = Loader::Batch::SummaryCounts::AsStatusReporter::ForAcceptedNames
             .new("*", session[:default_loader_batch_id] || 0).report
  end

  def processing_overview
    render "processing_overview"
  end

  def hide_processing_overview; end
  def bulk_operation
    render "bulk/operation"
  end

  def default_reference_suggestions
    render json: [] if params[:term].blank?
    render json: Reference::AsTypeahead::OnCitation.new(params[:term]).results
  end

  def unlock
    Loader::Batch::Bulk::JobLock.unlock!
    render js: "$('#emergency-unlock-link').hide();"
  end

  private

  def find_loader_batch
    @loader_batch = Loader::Batch.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the loader batch record."
    redirect_to loader_batches_path
  end

  def loader_batch_params
    params.require(:loader_batch).permit(:name, :description,
                                         :default_reference_id,
                                         :default_reference_typeahead)
  end

  def set_tab
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             "tab_details"
           end
  end

  def set_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end
end
