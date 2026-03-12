# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reference, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:products).with_foreign_key('reference_id') }
  end

  describe "#not_used_by_any_related_table?" do
    let(:reference) { create(:reference) }

    context "when reference has no instances and no profile_item_references" do
      it "returns true" do
        expect(reference.not_used_by_any_related_table?).to eq true
      end
    end

    context "when reference has instances" do
      before do
        create(:instance, reference: reference)
      end

      it "returns false" do
        expect(reference.not_used_by_any_related_table?).to eq false
      end
    end

    context "when reference has profile_item_references" do
      before do
        profile_item = create(:profile_item)
        create(:profile_item_reference, profile_item: profile_item, reference: reference)
      end

      it "returns false" do
        expect(reference.not_used_by_any_related_table?).to eq false
      end
    end

    context "when reference has both instances and profile_item_references" do
      before do
        create(:instance, reference: reference)
        profile_item = create(:profile_item)
        create(:profile_item_reference, profile_item: profile_item, reference: reference)
      end

      it "returns false" do
        expect(reference.not_used_by_any_related_table?).to eq false
      end
    end
  end
end
