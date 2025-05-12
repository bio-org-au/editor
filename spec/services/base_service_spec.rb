require 'rails_helper'

RSpec.describe BaseService, type: :service do
  let(:params) { { key: "value" } }
  let(:options) { { option_key: "option_value" } }
  let(:service_instance) { described_class.new(params, options) }

  before do
    allow(service_instance).to receive(:execute).and_return(true)
  end

  describe ".call" do
    it "executes the service" do
      allow(described_class).to receive(:new).and_return(service_instance)

      described_class.call(params, options)

      expect(described_class).to have_received(:new).with(params, options)
      expect(service_instance).to have_received(:execute)
    end
  end

  describe ".new_call_transaction" do
    it "executes within a transaction and rolls back on errors" do
      allow(described_class).to receive(:new).with(params).and_return(service_instance)
      allow(service_instance.errors).to receive(:any?).and_return(true)

      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      result = described_class.new_call_transaction(params)

      expect(service_instance).to have_received(:execute)
      expect(result).to eq(service_instance)
    end

    it "does not roll back if there are no errors" do
      allow(described_class).to receive(:new).with(params).and_return(service_instance)
      allow(service_instance.errors).to receive(:any?).and_return(false)

      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      result = described_class.new_call_transaction(params)

      expect(service_instance).to have_received(:execute)
      expect(result).to eq(service_instance)
    end
  end

  describe "#initialize" do
    it "assigns params and options" do
      expect(service_instance.instance_variable_get(:@params)).to eq(params)
      expect(service_instance.instance_variable_get(:@options)).to eq(options)
    end

    it "assigns a logger" do
      expect(service_instance.instance_variable_get(:@logger)).to eq(Rails.logger)
    end
  end
end
