require 'rails_helper'

RSpec.describe ProductContexts::SetContextController, type: :controller do
  let!(:session_user) { FactoryBot.create(:session_user, groups: ['login']) }
  let!(:current_user) { FactoryBot.create(:user) }
  let!(:context_id) { 1 }
  let!(:context_name) { 'Test Context' }
  let!(:available_contexts) do
    [
      { context_id: 1, name: 'Test Context', description: 'A test context' },
      { context_id: 2, name: 'Another Context', description: 'Another test context' }
    ]
  end

  before do
    emulate_user_login(session_user, current_user)

    allow(controller).to receive(:available_contexts_for_current_user).and_return(available_contexts)
    allow(controller).to receive(:product_context_service).and_return(double(available_contexts: available_contexts))
  end

  describe "POST #create" do
    subject(:post_create) { post :create, params: { context_id: context_id } }

    it "sets the current context in the session" do
      post_create
      expect(session[:current_context_id]).to eq(context_id)
    end

    it "sets the current context name in the session" do
      post_create
      expect(session[:current_context_name]).to eq("Test Context")
    end

    it "redirects to the previous page when HTTP_REFERER is set" do
      request.env["HTTP_REFERER"] = "/previous_page"
      post_create
      expect(response).to redirect_to("/previous_page")
    end

    it "falls back to search page" do
      post_create
      expect(response).to redirect_to(search_path)
    end

    context "with the same context id" do
      let!(:context_id) { 1 }

      before do
        session[:current_context_id] = context_id
        session[:current_context_name] = context_name
      end

      it "clears the current context from the session" do
        post_create
        expect(session[:current_context_id]).to be_nil
        expect(session[:current_context_name]).to be_nil
      end
    end

    context "with invalid context" do
      let(:context_id) { "invalid" }

      it "does not change the current context in the session" do
        post_create
        expect(session[:current_context_id]).to be_nil
      end

      it "redirects to the previous page when HTTP_REFERER is set" do
        request.env["HTTP_REFERER"] = "/previous_page"
        post_create
        expect(response).to redirect_to("/previous_page")
      end
    end
  end

end
