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
    end

    private

    def set_source_profile_item
      @source_profile_item = Profile::ProfileItem.find(params[:id])
    end
  end
end
