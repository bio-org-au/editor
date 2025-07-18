class Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs
  attr_reader :product,
              :instance,
              :product_configs_and_profile_items

  SUPPORTED_PRODUCTS = ["FOA"].freeze

  def initialize(session_user, instance, params = {})
    @session_user = session_user
    @user = session_user.user
    @product = find_product_by_name
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

  attr_reader :user, :params

  def find_product_by_name
    product_name = user.products.where(name: SUPPORTED_PRODUCTS).first&.name

    Product.find_by(name: product_name)
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
        .includes([
          :sourced_in_profile_items,
          :profile_item_annotation,
          :profile_item_references,
          :profile_text
        ])
        .order(created_at: :desc)

   return existing_profile_items if params[:all]

    existing_profile_items.group_by(&:product_item_config_id).transform_values { |items| items.first }
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
