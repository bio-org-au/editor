module Products
  class ProductContextService < BaseService

    attr_reader :products

    def initialize(products:, params: nil)
      super(params)
      @products = products
    end

    def execute
      available_contexts
    end

    def available_contexts
      @available_contexts ||= if Rails.configuration.try(:multi_product_tabs_enabled)
        products.blank? ? [] : product_contexts
      else
        []
      end
    end

    def product_with_context(context_id)
      return nil if context_id.nil? || products.blank?

      products.find { |product| product.context_id == context_id }
    end

    private

    def product_contexts
      @product_contexts ||= query_product_context
        .select { |ctx| (ctx[:products] & products).any? }
    end

    def query_product_context
      products
        .group_by(&:context_id)
        .transform_values { |p| p.map(&:name).join('/') }
        .to_h
        .map do |context_id, context_list|
        {
          context_id: context_id,
          name: context_list,
          description: context_list,
          products: products_for_context(context_id)
        }
      end.uniq{|ctx| ctx[:context_id]}
    end

    def products_for_context(context_id)
      Product.where(context_id: context_id).order(:context_sort_order)
    end
  end
end
