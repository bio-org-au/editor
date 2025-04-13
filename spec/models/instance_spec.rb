require 'rails_helper'

RSpec.describe Instance, type: :model do
  describe "#secondary_reference?" do
    let(:instance) { FactoryBot.create(:instance, instance_type: instance_type) }

    context "when instance type is not a secondary instance" do
      let(:instance_type) { FactoryBot.create(:instance_type, secondary_instance: false)}
      it "returns false" do
        expect(instance.secondary_reference?).to eq false
      end
    end

    context "when instance type is a secondary instance" do
      let(:instance_type) { FactoryBot.create(:instance_type, secondary_instance: true)}
      it "returns true" do
        expect(instance.secondary_reference?).to eq true
      end
    end
  end
end
