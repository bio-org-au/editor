require 'rails_helper'

RSpec.describe Instance, type: :model do
  describe "#delete_as_user" do
    let(:instance_type) { FactoryBot.create(:instance_type, secondary_instance: false)}
    let(:instance) { FactoryBot.create(:instance, instance_type: instance_type) }
    let(:username) { "test_user" }

    context "when deletion is successful" do
      before do
        allow(Instance::AsServices).to receive(:delete).with(instance.id).and_return(true)
        allow(instance).to receive(:cleanup_records)
      end

      it "updates the updated_by field with the username" do
        expect(instance).to receive(:update_attribute).with(:updated_by, username)
        instance.delete_as_user(username)
      end

      it "calls cleanup_records" do
        expect(instance).to receive(:cleanup_records)
        instance.delete_as_user(username)
      end
    end

    context "when deletion fails" do
      before do
        allow(Instance::AsServices).to receive(:delete).with(instance.id).and_return(false)
        allow(instance).to receive(:cleanup_records)
      end

      it "does not call cleanup_records" do
        expect(instance).not_to receive(:cleanup_records)
        instance.delete_as_user(username)
      end
    end

    context "when an exception occurs" do
      before do
        allow(Instance::AsServices).to receive(:delete).with(instance.id).and_raise(StandardError, "Deletion failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs the exception" do
        expect(Rails.logger).to receive(:error).with(/delete_as_user exception: Deletion failed/)
        expect { instance.delete_as_user(username) }.to raise_error(StandardError, "Deletion failed")
      end

      it "raises the exception" do
        expect { instance.delete_as_user(username) }.to raise_error(StandardError, "Deletion failed")
      end
    end
  end

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
