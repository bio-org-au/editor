class Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs
  attr_reader :product,
              :instance,
              :product_configs_and_profile_items

  def initialize(user, instance, params = {})
    @user = user
    @profile_context = user.profile_v2_context
    @product = find_product_by_name(@profile_context.product)
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
    if profile_v2_aware?
      @product_configs_and_profile_items = find_or_initialize_profile_items
    end

    [product_configs_and_profile_items, product]
  end

  private

  def find_product_by_name(name)
    Profile::Product.find_by(name: name)
  end

  def profile_v2_aware?
    Rails.configuration.try('profile_v2_aware')
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
        .joins("left join profile_item_type AS pit ON pit.id = product_item_config.profile_item_type_id")
        .joins("inner join profile_object_type As pot ON pot.id = pit.profile_object_type_id")
        .where("pot.rdf_id = ?", @params[:rdf_id] || "text")
        .where.not(display_html: nil)

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
