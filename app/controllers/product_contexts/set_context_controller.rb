# frozen_string_literal: true

module ProductContexts
  class SetContextController < ApplicationController

    def create
      context_id = permitted_params[:context_id]

      if valid_context_for_user?(context_id)
        session[:current_context_id] != context_id.to_i ? set_context(context_id) : clear_context_session
        Rails.logger.info "Context switched to: #{session[:current_context_name]}"
      else
        Rails.logger.warn "Attempted to switch to invalid context: #{context_id}"
      end

      redirect_back(fallback_location: search_path)
    end

    private

    def set_context(context_id)
      set_context_session(context_id)
      current_user.set_current_product_from_context(product_context_service.product_with_context(context_id.to_i))
    end

    def clear_context_session
      session.delete(:current_context_id)
      session.delete(:current_context_name)
      session.delete(:draft)
    end

    def set_context_session(context_id)
      session[:current_context_id] = context_id.to_i
      session[:current_context_name] = context_name_for_id(context_id)
      session.delete(:draft)
    end

    def permitted_params
      params.permit(:context_id)
    end

    def valid_context_for_user?(context_id)
      return false unless context_id

      available_context_ids = available_contexts_for_current_user.map { |ctx| ctx[:context_id] }
      available_context_ids.include?(context_id.to_i)
    end

    def context_name_for_id(context_id)
      context = available_contexts_for_current_user.find { |ctx| ctx[:context_id] == context_id.to_i }
      context ? context[:name] : "Unknown Context"
    end

    def available_contexts_for_current_user
      @available_contexts_for_current_user ||= product_context_service
        .available_contexts
        .sort_by { |ctx| ctx[:name] }
    end
  end

end
