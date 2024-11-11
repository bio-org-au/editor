class Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs
  attr_reader :product,
              :instance,
              :product_configs_and_profile_items

  def initialize(instance, params = {})
    @product = find_product_by_name("FOA")
    @product_configs_and_profile_items = []
    @instance = instance
    @params = params
  end

  def debug(s)
    tag = "Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs"
    Rails.logger.debug("#{tag}: #{s}")
  end

  def run_query
    debug("run_query")
    
    if foa_profile_aware?
      @product_configs_and_profile_items = find_or_initialize_profile_items
    end

    [product_configs_and_profile_items, product]
  end

  private

  def find_product_by_name(name)
    Profile::Product.find_by(name: name)
  end

  def foa_profile_aware?
    Rails.configuration.try('foa_profile_aware')
  end

  def find_or_initialize_profile_items
    return [] unless @product && @instance

    product_item_configs = fetch_product_item_configs

    existing_profile_items = fetch_existing_profile_items(product_item_configs)

    map_product_item_configs_to_profile_items(product_item_configs, existing_profile_items)
  end

  def fetch_product_item_configs
    product_item_configs =
      Profile::ProductItemConfig
        .where(product_id: @product.id)
        .includes(:profile_items)
        .where.not(display_html: nil)
        .order(sort_order: "ASC")

    product_item_configs = product_item_configs.where(id: @params[:product_item_config_id]) if @params[:product_item_config_id]
    product_item_configs
  end

  def fetch_existing_profile_items(product_item_configs)
    existing_profile_items =
      Profile::ProfileItem
        .where(
          product_item_config_id: product_item_configs.pluck(:id),
          instance_id: @instance.id
        )
        .index_by(&:product_item_config_id)

    existing_profile_items
  end

  def map_product_item_configs_to_profile_items(product_item_configs, existing_profile_items)
    product_item_configs.map do |product_item_config|
      profile_item = find_or_initialize_profile_item(
        product_item_config,
        existing_profile_items[product_item_config.id]
      )

      { product_item_config: product_item_config, profile_item: profile_item }
    end
  end

  def find_or_initialize_profile_item(product_item_config, existing_profile_item)
    return existing_profile_item if existing_profile_item

    Profile::ProfileItem.new(
      product_item_config: product_item_config,
      instance_id: @instance.id
    )
  end
end
