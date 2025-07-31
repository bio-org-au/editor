require 'rails_helper'

describe ProfileItems::VersionedCopiesController, type: :controller do
  let(:session_user) { create(:session_user, groups: ['login']) }
  let(:current_user) { create(:user) }

  before do
    emulate_user_login(session_user, current_user)
    allow(controller).to receive(:can?).and_return("profile_items", :all)
  end

  describe 'POST #create' do
    let(:instance) { instance_double("Instance", id: 1) }
    let(:profile_item) { instance_double("Profile::ProfileItem", id: 1, profile_text_id: 1, product_item_config_id: 1, fact?: true) }
    let(:new_profile_item) { instance_double("Profile::ProfileItem", id: 2, product_item_config_id: 1) }
    let(:mock_service_result) { double("ProfileItems::Published::CreateNewVersionService", new_profile_item: new_profile_item, errors: {}) }
    let(:mock_product_and_product_item_config_result) { double("Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs", run_query: [[], nil]) }
    let(:params) { { instance_id: instance.id, id: profile_item.id } }

    subject { post :create, params: params, format: :turbo_stream }

    before do
      allow(Instance).to receive(:find).with(params[:instance_id].to_s).and_return(instance)
      allow(Profile::ProfileItem).to receive(:find).with(profile_item.id.to_s).and_return(profile_item)
      allow(Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs).to receive(:new).and_return(mock_product_and_product_item_config_result)
    end

    context 'when service succeeds' do
      before do
        allow(mock_service_result.errors).to receive(:any?).and_return(false)
        allow(ProfileItems::Published::CreateNewVersionService).to receive(:call).and_return(mock_service_result)
      end

      it 'calls the service with correct arguments' do
        subject
        expect(ProfileItems::Published::CreateNewVersionService).to have_received(:call)
      end

      it "assigns the created version of the profile item to @new_profile_item" do
        subject
        expect(assigns(:new_profile_item)).to eq(new_profile_item)
      end

       it "renders the profile_items/index" do
        subject
        expect(response).to render_template("profile_items/index")
      end

      it "does not render create_failed" do
        subject
        expect(response).not_to render_template("create_failed")
      end

      it "assigns @product_configs_and_profile_items" do
        subject
        expect(assigns(:product_configs_and_profile_items)).to eq([])
      end
    end

    context 'when service returns errors' do
      let(:errors) { double('errors', any?: true, full_messages: ["Some error"]) }
      let(:mock_service_result) { double("ProfileItems::Published::CreateNewVersionService", new_profile_item: nil, errors: errors) }

      before do
        allow(ProfileItems::Published::CreateNewVersionService).to receive(:call).and_return(mock_service_result)
      end

      it 'assigns @message and renders create_failed' do
        subject
        expect(assigns(:message)).to include('Error creating versioned copy of a profile item: Some error')

      end

      it "renders the 'create_failed' template" do
        subject
        expect(response).to render_template('create_failed')
      end
    end

    context "when user is not authorized" do
      before do
        allow(controller).to receive(:can?).and_return(false)
      end

      it "returns a 403 Forbidden response" do
        subject
        expect(response).to have_http_status(:forbidden)
      end

      it "does not call the service" do
        expect(ProfileItems::Published::CreateNewVersionService).not_to receive(:call)
        subject
      end
    end
  end
end
