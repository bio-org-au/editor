require 'rails_helper'

RSpec.describe ProfileItemsController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ['login']) }
  let(:current_user) { FactoryBot.create(:user) }

  let(:instance) { FactoryBot.create(:instance) }
  let(:profile_item) { FactoryBot.create(:profile_item, instance: instance) }

  before do
    emulate_user_login(session_user, current_user)
    allow(controller).to receive(:can?).and_return(true)
  end

  describe "GET #show" do
    before do
      allow(Profile::ProfileItem).to receive(:find).with(profile_item.id.to_s).and_return(profile_item)
    end

    subject { get :show, params: { id: profile_item.id, tab: "details", take_focus: "true" } }

    it "assigns the profile item" do
      subject
      expect(assigns(:profile_item)).to eq(profile_item)
    end

    it "renders the 'show' template" do
      subject
      expect(response).to render_template("show")
    end
  end

  describe "GET #details" do
    before do
      allow(Instance).to receive(:find_by).with(id: instance.id.to_s).and_return(instance)
    end

    subject { get :details, params: { id: profile_item.id, instance_id: instance.id }, format: :turbo_stream }

    it "assigns the selected instance" do
      subject
      expect(assigns(:selected_instance)).to eq(instance)
    end

    it "responds with turbo_stream format" do
      subject
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "GET #index" do
    let(:query_result) { double("QueryResult") }

    before do
      allow(Instance).to receive(:find_by!).with(id: instance.id.to_s).and_return(instance)
      allow(Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs).to receive_message_chain(:new, :run_query).and_return([query_result, nil])
    end

    subject { get :index, params: { instance_id: instance.id }, format: :turbo_stream }

    it "assigns the instance" do
      subject
      expect(assigns(:instance)).to eq(instance)
    end

    it "assigns the product configs and profile items" do
      subject
      expect(assigns(:product_configs_and_profile_items)).to eq(query_result)
    end
  end

  describe "DELETE #destroy" do
    before do
      allow(Profile::ProfileItem).to receive(:find).with(profile_item.id.to_s).and_return(profile_item)
    end

    subject { delete :destroy, params: { id: profile_item.id }, format: :turbo_stream  }

    it "assigns a profile_item_id" do
      subject
      expect(assigns[:profile_item_id]).to eq(profile_item.id)
    end

    it "assigns a profile_item_config_id" do
      subject
      expect(assigns[:product_item_config]).to eq(profile_item.product_item_config)
    end

    it "assigns an instance_id" do
      subject
      expect(assigns[:instance_id]).to eq(profile_item.instance_id)
    end

    context "when destroy is successful" do
      before do
        allow(profile_item).to receive(:destroy).and_return(true)
      end

      it "assigns a success message" do
        subject
        expect(assigns(:message)).to eq("Deleted profile item.")
      end
    end

    context "when destroy fails" do
      before do
        allow(profile_item).to receive(:destroy).and_raise(StandardError, "Something went wrong")
      end

      it "assigns an error message" do
        subject
        expect(assigns(:message)).to eq("Error deleting profile item: Something went wrong")
      end

      it "renders the 'destroy_failed' template with unprocessable_content status" do
        subject
        expect(response).to render_template("destroy_failed")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
