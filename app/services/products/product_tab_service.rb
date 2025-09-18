
module Products
  class ProductTabService < BaseService

    attr_reader :active_flags, :enabled_models, :context_id, :products

    def self.for_context(context_id, config = ProductTabConfig.new)
      products = products_for_context(context_id)
      call(products, config, context_id: context_id)
    end

    def self.products_for_context(context_id)
      Product.where(context_id: context_id)
    end

    def initialize(products, config = ProductTabConfig.new, context_id: nil)
      @products = Array(products).compact
      @config = config
      @context_id = context_id
      @active_flags = []
      @enabled_models = []
      @result = {}
      @product_tabs = {}

      filter_products_by_context if @context_id
    end

    def execute
      determine_active_flags
      determine_enabled_models
      build_result
      build_product_tabs
      self
    end

    def available_tabs_for(model)
      return [] if model.nil?

      @result[model.to_s] || []
    end

    def tab_options_for(model, tab)
      available_tabs_for(model).find { |t| t[:tab] == tab.to_s }
    end

    def all_available_tabs
      @result
    end

    def tabs_per_product
      @product_tabs
    end


    private

    def determine_active_flags
      return if @products.empty?

      all_flags = Set.new

      @products.each do |product|
        @config.flag_config.keys.each do |flag|
          begin
            all_flags << flag if product.respond_to?(flag) && product.public_send(flag)
          rescue NoMethodError
            Rails.logger.warn("NoMethodError: Product #{product.id} does not have flag #{flag}")
          end
        end
      end

      @active_flags = all_flags.to_a
    end

    def determine_enabled_models
      @enabled_models = @config.enabled_models_for_flags(@active_flags)
    end

    def build_result
      @enabled_models.each do |model|
        @result[model] = []

        @products.each do |product|
          product_flags = determine_flags_for_product(product)
          tabs = @config.tabs_for(model, product_flags).uniq

          tabs.each do |tab|
            @result[model] << {
              tab: tab,
              product: product
            }
          end
        end
      end
    end

    def build_product_tabs
      @products.each do |product|
        product_flags = determine_flags_for_product(product)
        enabled_models = @config.enabled_models_for_flags(product_flags)

        @product_tabs[product] = {}
        enabled_models.each do |model|
          @product_tabs[product][model] = @config.tabs_for(model, product_flags)
        end
      end
    end

    def determine_flags_for_product(product)
      flags = []

      @config.flag_config.keys.each do |flag|
        begin
          flags << flag if product.respond_to?(flag) && product.public_send(flag)
        rescue NoMethodError
          Rails.logger.warn("NoMethodError: Product #{product.id} does not have flag #{flag}")
        end
      end

      flags
    end

    def filter_products_by_context
      return unless @context_id

      context_products = self.class.products_for_context(@context_id)
      @products = @products.select { |product| context_products.include?(product) }
    end
  end
end
