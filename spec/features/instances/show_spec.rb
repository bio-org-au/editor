require 'rails_helper'

RSpec.feature "InstancesShow", type: :feature do
  let(:user) { FactoryBot.create(:session_user) }
  let(:instance) { FactoryBot.create(:instance) }
  let(:profile_v2_context) { double('ProfileV2Context') }

  before do
    allow_any_instance_of(SessionUser).to receive(:profile_v2_context).and_return(profile_v2_context)
    allow(profile_v2_context).to receive(:product).and_return('Test Product')
    allow(Rails.configuration).to receive(:try).with('profile_v2_aware').and_return(true)
    allow(Rails.configuration).to receive(:try).with('environment').and_return('Test')
    allow(Rails.configuration).to receive(:try).with('path_to_broadcast_file').and_return(nil)
    allow(Rails.configuration).to receive(:try).with('offer_feedback_link').and_return(nil)
    allow(Rails.configuration).to receive(:try).with('config_file_tag').and_return(nil)

    allow(Profile::Product).to receive(:find_by).with(name: 'Test Product').and_return(FactoryBot.create(:product, name: 'Test Product'))

    # Mocking LDAP authentication
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)

  end

  scenario 'User views the instance details page' do
    visit instance_path(instance)

    expect(page).to have_content("#{instance.type_of_instance} instance")
    expect(page).to have_selector('.focus-details')
    expect(page).to have_selector('.heading-for-show-details')
    expect(page).to have_link("#{instance.type_of_instance} instance", href: search_path(query_string: "id: #{instance.id}", query_target: 'instance'))
    expect(page).to have_selector('.server-response-time')
  end

  scenario 'User sees the correct tabs' do
    visit instance_path(instance)

    expect(page).to have_selector('#instance-show-tab')
    expect(page).to have_selector('#instance-edit-tab')
    expect(page).to have_selector('#instance-edit-notes-tab')
    expect(page).to have_selector('#instance-cite-this-instance-tab')
    expect(page).to have_selector('#unpublished-citation-tab')
    expect(page).to have_selector('#instance-classification-tab')
    expect(page).to have_selector('#instance-comments-tab')
    expect(page).to have_selector('#instance-batch-loader-tab')
    expect(page).to have_selector('#instance-profile-v2-tab')
  end
end
