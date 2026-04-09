# frozen_string_literal: true

require "rails_helper"

RSpec.describe Name, type: :model do
  describe "associations" do
    describe "name_resources dependent destroy" do
      context "when name has associated name_resources" do
        let!(:name) { create(:name) }
        let!(:name_resource) { create(:name_resource, name: name) }

        it "destroys associated name_resources when name is destroyed" do
          name_resource_id = name_resource.id
          name.destroy
          expect(NameResource.exists?(name_resource_id)).to be false
        end

        it "destroys the name successfully" do
          expect { name.destroy }.to change(Name, :count).by(-1)
        end
      end

      context "when name has no associated name_resources" do
        let!(:name) { create(:name) }

        it "allows destruction when no name_resources exist" do
          expect { name.destroy }.to change(Name, :count).by(-1)
        end
      end
    end
  end

  describe "#allow_delete?" do
    let(:name) { create(:name) }

    context "when name has instances" do
      let!(:instance) { create(:instance, name: name) }

      it "returns false" do
        expect(name.allow_delete?).to be false
      end
    end

    context "when name has children" do
      let!(:child) { create(:name, parent: name) }

      it "returns false" do
        expect(name.allow_delete?).to be false
      end
    end

    context "when name has comments" do
      let!(:comment) { create(:comment, name: name) }

      it "returns false" do
        expect(name.allow_delete?).to be false
      end
    end

    context "when name has duplicates" do
      let!(:duplicate) { create(:name, duplicate_of: name) }

      it "returns false" do
        expect(name.allow_delete?).to be false
      end
    end

    context "when name has name_resources" do
      let!(:name_resource) { create(:name_resource, name: name) }

      it "returns true as name_resources will be destroyed automatically" do
        expect(name.allow_delete?).to be true
      end
    end

    context "when name has no dependencies" do
      it "returns true" do
        expect(name.allow_delete?).to be true
      end
    end
  end

  describe "#no_name_resource_dependents?" do
    let(:name) { create(:name) }

    before do
      allow(Rails.configuration).to receive(:try).with(:resource_tab_enabled).and_return(true)
    end
    context "when name has name_resources" do
      let!(:name_resource) { create(:name_resource, name: name) }

      it "returns false" do
        expect(name.no_name_resource_dependents?).to be false
      end
    end

    context "when name has no name_resources" do
      it "returns true" do
        expect(name.no_name_resource_dependents?).to be true
      end
    end

    context "when resource_tab_enabled is false" do
      before do
        allow(Rails.configuration).to receive(:try).with(:resource_tab_enabled).and_return(false)
      end

      it "returns true regardless of name_resources" do
        expect(name.no_name_resource_dependents?).to be true
      end
    end
  end
end
