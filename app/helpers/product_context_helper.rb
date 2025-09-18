module ProductContextHelper

  def available_contexts_for_current_user
    return [] unless current_registered_user&.available_products_from_roles

    product_context_service.available_contexts.sort_by { |ctx| ctx[:context_id] }
  end
end
