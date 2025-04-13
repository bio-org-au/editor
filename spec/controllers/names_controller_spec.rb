require 'rails_helper'

RSpec.describe NamesController, type: :controller do
  describe 'GET #show' do
    let(:user) { FactoryBot.create(:session_user, groups: ['login','edit']) }
    let(:name) { FactoryBot.create(:name) }

    before do
      session[:username] = user.username
      session[:user_full_name] = user.full_name
      session[:groups] = user.groups

      controller.instance_variable_set(:@current_user, user)
      allow(controller).to receive(:pick_a_tab)
      allow(controller).to receive(:pick_a_tab_index)
    end

    context "when user is not authorized" do
      let(:user) { FactoryBot.create(:session_user) }
      it "redirects to the login page" do
        get :show, params: { id: name.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when change_category_name_to is present' do
      it 'sets @name.change_category_name_to to scientific' do
        get :show, params: { id: name.id, change_category_name_to: 'scientific' }
        expect(assigns(:name).change_category_name_to).to eq('scientific')
      end
    end

    context 'when tab is tab_instances or tab_instances_profile_v2' do
      it 'initializes a new instance and assigns it to @instance' do
        get :show, params: { id: name.id, tab: 'tab_instances' }
        expect(assigns(:instance)).to be_a_new(Instance)
        expect(assigns(:instance).name).to eq(name)

        get :show, params: { id: name.id, tab: 'tab_instances_profile_v2' }
        expect(assigns(:instance)).to be_a_new(Instance)
        expect(assigns(:instance).name).to eq(name)
      end
    end

    context 'when take_focus is true' do
      it 'sets @take_focus to true' do
        get :show, params: { id: name.id, take_focus: 'true' }
        expect(assigns(:take_focus)).to be true
      end
    end

    context 'when take_focus is false' do
      it 'sets @take_focus to false' do
        get :show, format: :js, params: { id: name.id, take_focus: 'false' }
        expect(assigns(:take_focus)).to be false
      end
    end

    it 'renders the show template with layout false' do
      get :show, params: { id: name.id }
      expect(response).to render_template('show')
      expect(response).to render_template(layout: false)
    end
  end
end
