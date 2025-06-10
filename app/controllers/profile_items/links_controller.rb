module ProfileItems
  class LinksController < ProfileItemsController

    skip_before_action :set_profile_item
    skip_before_action :authorise_user!

    before_action :set_source_profile_item

    def create
      @instance = Instance.find(params[:instance_id])
      result = ProfileItems::Links::CreateService.call(
        instance: @instance,
        source_profile_item: @source_profile_item,
        user: current_registered_user,
        params: params
      )
      @profile_item = result.profile_item

      if result.errors.any?
        @message = "Error deleting profile item: #{result.errors.full_messages.to_sentence}"
        render "create_failed"
      end
    end

    def update
      result = ProfileItems::Links::UpdateService.call(
        profile_item: @source_profile_item,
        user: current_registered_user,
        params: params
      )

      if result.errors.any?
        @message = "Error deleting profile item: #{result.errors.full_messages.to_sentence}"
        render "update_failed"
      else
        @profile_item = result.profile_item
        @profile_text = result.profile_text
        @instance = @profile_item.instance
        @product_configs_and_profile_items, _product = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs
          .new(@current_user, @instance, {
            instance_id: @instance.id,
            product_item_config_id: @profile_item.product_item_config_id
          }).run_query

        render "profile_items/index"
      end
    end

    private

    def set_source_profile_item
      @source_profile_item = Profile::ProfileItem.find(params[:id])
    end
  end
end
