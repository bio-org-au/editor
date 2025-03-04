class ProductContexts::SessionsController < ApplicationController

  def switch
    product_context = current_registered_user.product_contexts.find_by(context_id: params[:context_id])
    set_product_context(product_context)
    redirect_to :root
  end

  def clear
    set_product_context(current_registered_user.default_product_context)
    redirect_to :root
  end

  private

  def set_product_context(product_context = nil)
    product_context ||= current_registered_user.default_product_context

    return unless product_context

    session[:product_context_is_default] = product_context.is_default?
    session[:product_context_display_text] = product_context.products.map(&:name).join("/")
    session[:product_context_product_id] = product_context.products.pluck(:id).first
  end
end
