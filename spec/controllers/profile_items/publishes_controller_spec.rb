require 'rails_helper'

describe ProfileItems::PublishesController, type: :controller do
  let(:session_user) { create(:session_user, groups: ['login']) }
  let(:current_user) { create(:user) }

  before do
    emulate_user_login(session_user, current_user)
    allow(controller).to receive(:can?).and_return("profile_items", :all)
    allow(controller).to receive(:current_registered_user).and_return(current_user)
  end

  describe 'POST #create' do
    let(:profile_item) { create(:profile_item) }
    let(:instance) { profile_item.instance }
    let(:service_errors) { ActiveModel::Errors.new("Some error") }
    let(:mock_product_and_product_item_config_result) { double("Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs", run_query: [[], nil]) }
    let(:params) { { instance_id: instance.id, id: profile_item.id } }

    subject { post :create, params: params, format: :turbo_stream }

    before do
      allow(Instance).to receive(:find).with(params[:instance_id].to_s).and_return(instance)
      allow(Profile::ProfileItem).to receive(:find).with(profile_item.id.to_s).and_return(profile_item)
      allow(Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs).to receive(:new).and_return(mock_product_and_product_item_config_result)
    end

    context 'when publish succeeds' do
      before { allow(profile_item).to receive(:publish!).and_return(true) }

      it 'calls publish! and renders index' do
        subject
        expect(profile_item).to have_received(:publish!)
        expect(response).to render_template('profile_items/index')
      end

      it "assigns @product_configs_and_profile_items" do
        subject
        expect(assigns(:product_configs_and_profile_items)).to eq([])
      end

      it "sets the current user on the profile item" do
        subject
        expect(profile_item.current_user).to eq(current_user)
      end
    end

    context 'when publish fails' do
      before do
        allow(profile_item).to receive(:publish!).and_return(false)
        allow(profile_item).to receive_message_chain(:errors, :full_messages).and_return(["Some error"])
      end

      it 'assigns @message and renders create_failed' do
        subject
        expect(assigns(:message)).to include('Error publishing profile item')
      end

      it "renders the create_field template" do
        subject
        expect(response).to render_template("create_failed")
      end
    end

    context "when user is not authorized" do
      before do
        allow(controller).to receive(:can?).with(:publish, profile_item).and_return(false)
      end

      it "returns a 403 Forbidden response" do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
