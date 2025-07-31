module ProfileItems
  class PublishesController < ProfileItemsController

    before_action :set_profile_item
    before_action :authorise_user!, only: [:create]

    def create
      @instance = Instance.find(params[:instance_id])
      @profile_item.current_user = current_registered_user

      if @profile_item.publish!
        @product_configs_and_profile_items, _product = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs
        .new(@current_user, @instance, {
          instance_id: @instance.id,
          product_item_config_id: @profile_item.product_item_config_id
        }).run_query

        render "profile_items/index"
      else
        @message = "Error publishing profile item: #{@profile_item.errors.full_messages.to_sentence}"
        render "create_failed"
      end
    end

     private

    def authorise_user!
      raise CanCan::AccessDenied.new("Access Denied!", :publish, @profile_item) unless can? :publish, @profile_item
    end
  end
end
