# frozen_string_literal: true

require "rails_helper"

RSpec.describe Name, type: :model do
  describe "associations" do
    describe "name_resources dependent restriction" do
      context "when name has associated name_resources" do
        let!(:name) { create(:name) }
        let!(:name_resource) { create(:name_resource, name: name) }

        it "raises ActiveRecord::DeleteRestrictionError when attempting to destroy" do
          expect { name.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError)
        end

        it "prevents deletion and keeps the record persisted" do
          expect { name.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError)
          expect(Name.exists?(name.id)).to be true
        end
      end

      context "when name has no associated name_resources" do
        let!(:name) { create(:name) }

        it "allows destruction when no name_resources exist" do
          expect { name.destroy }.not_to raise_error(ActiveRecord::DeleteRestrictionError)
        end
      end
    end
  end

  describe "#allow_delete?" do
    let(:name) { create(:name) }

    context "when name has name_resources" do
      let!(:name_resource) { create(:name_resource, name: name) }
      it "returns false" do
        expect(name.allow_delete?).to be false
      end

      context "when resource_tab_enabled is false" do
        before do
          allow(Rails.configuration).to receive(:resource_tab_enabled).and_return(false)
        end

        it "returns true when only name_resources exist" do
          expect(name.allow_delete?).to be true
        end
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
