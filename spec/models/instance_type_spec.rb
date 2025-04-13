require 'rails_helper'

RSpec.describe InstanceType, type: :model do
  describe "#secondary_instance?" do
    context "when instance type is not a secondary instance" do
      let(:instance_type) { FactoryBot.create(:instance_type, secondary_instance: false) }
      it "returns false" do
        expect(instance_type.secondary_instance?).to eq false
      end
    end

    context "when instance type is a secondary instance" do
      let(:instance_type) { FactoryBot.create(:instance_type, secondary_instance: true) }
      it "returns true" do
        expect(instance_type.secondary_instance?).to eq true
      end
    end
  end

  describe ".synonym_options" do
    let!(:instance_type1) { FactoryBot.create(:instance_type, name: 'Type A', relationship: true, deprecated: false, unsourced: false) }
    let!(:instance_type2) { FactoryBot.create(:instance_type, name: 'Type B', relationship: true, deprecated: false, unsourced: false) }
    let!(:instance_type3) { FactoryBot.create(:instance_type, name: 'Type C', relationship: true, deprecated: true, unsourced: false) }
    let!(:instance_type4) { FactoryBot.create(:instance_type, name: 'Type D', relationship: true, deprecated: false, unsourced: true) }
    let!(:instance_type5) { FactoryBot.create(:instance_type, name: 'Type E', relationship: false, deprecated: false, unsourced: false) }

    it 'returns only instance types with relationship true, not deprecated, and not unsourced' do
      result = InstanceType.synonym_options
      expect(result).to contain_exactly(
        [instance_type1.name, instance_type1.id],
        [instance_type2.name, instance_type2.id]
      )
    end

    it 'returns the instance types sorted by name' do
      result = InstanceType.synonym_options
      expect(result).to eq([
        [instance_type1.name, instance_type1.id],
        [instance_type2.name, instance_type2.id]
      ].sort_by(&:first))
    end
  end

  describe '.unpublished_citation_options' do
    let!(:instance_type1) { FactoryBot.create(:instance_type, name: 'Type A', relationship: true, unsourced: true, deprecated: false) }
    let!(:instance_type2) { FactoryBot.create(:instance_type, name: 'Type B', relationship: true, unsourced: true, deprecated: false) }
    let!(:instance_type3) { FactoryBot.create(:instance_type, name: 'Type C', relationship: true, unsourced: true, deprecated: true) }
    let!(:instance_type4) { FactoryBot.create(:instance_type, name: 'Type D', relationship: true, unsourced: false, deprecated: false) }
    let!(:instance_type5) { FactoryBot.create(:instance_type, name: 'Type E', relationship: false, unsourced: true, deprecated: false) }

    it 'returns only instance types with relationship true, unsourced true, and not deprecated' do
      result = InstanceType.unpublished_citation_options
      expect(result).to contain_exactly(
        [instance_type1.name, instance_type1.id],
        [instance_type2.name, instance_type2.id]
      )
    end

    it 'returns the instance types sorted by name' do
      result = InstanceType.unpublished_citation_options
      expect(result).to eq([
        [instance_type1.name, instance_type1.id],
        [instance_type2.name, instance_type2.id]
      ].sort_by(&:first))
    end
  end
end
