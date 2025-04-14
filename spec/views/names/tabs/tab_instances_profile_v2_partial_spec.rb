require 'rails_helper'

RSpec.describe "names/tabs/_tab_instances_profile_v2.html.erb", type: :view do
  let(:session_user) { FactoryBot.create(:session_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:name) { FactoryBot.create(:name) }
  let(:instance) { FactoryBot.create(:instance, name: name) }
  let(:product) { FactoryBot.create(:product, name: "FOA") }
  let!(:language) { FactoryBot.create(:language, iso6391code: "en", iso6393code: "eng") }
  let!(:reference) { FactoryBot.create(:reference, language: language) }
  let!(:instance_type) { FactoryBot.create(:instance_type, name: "secondary reference") }

  before do
    allow(Profile::Product).to receive(:find_by).with(name: product.name).and_return(product)
    allow(product).to receive(:reference).and_return(reference)
    allow(user).to receive(:available_product_from_roles).and_return(product)

    assign(:current_user, session_user)
    assign(:current_registered_user, user)
    assign(:name, name)
    assign(:instance, instance)
  end

  context "for when a name is a duplicate" do
    before do
      allow(name).to receive(:duplicate?).and_return(true)
    end

    it "displays a message indicating that instances cannot be created for a duplicate name" do
      render partial: "names/tabs/tab_instances_profile_v2"

      expect(rendered).to include("Cannot create instances for a duplicate name.")
    end
  end

  context "for when the name is not a duplicate" do
    before do
      allow(name).to receive(:duplicate?).and_return(false)
    end

    it "displays the form for creating a new instance" do
      render partial: "names/tabs/tab_instances_profile_v2"

      expect(rendered).to have_selector("form")
      expect(rendered).to include("The new instance will remain attached to:")
      expect(rendered).to include(name.full_name)
      expect(rendered).to include("The new instance will be attached to the #{product.name} product reference:")
      expect(rendered).to include(reference.citation)
      expect(rendered).to have_selector("input[type=hidden][value='#{reference.id}']", visible: false)
      expect(rendered).to have_selector("input[type=hidden][value='#{InstanceType.secondary_reference.id}']", visible: false)
      expect(rendered).to have_selector("input[type=hidden][name='instance[name_id]']", visible: false)
      expect(rendered).to have_selector("input[type=submit][id='save-new-instance-btn']")
    end

    it "displays the instance type" do
      render partial: "names/tabs/tab_instances_profile_v2"

      expect(rendered).to include("Instance type:")
      expect(rendered).to include(instance.instance_type.name)
    end

    it "includes a hidden field for draft" do
      render partial: "names/tabs/tab_instances_profile_v2"

      expect(rendered).to have_selector("input[type=hidden][name='instance[draft]'][value='true']", visible: false)
    end
  end
end
