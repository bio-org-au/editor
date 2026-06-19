require 'rails_helper'

RSpec.describe NameType, type: :model do
  describe ".common_only_options" do
    let!(:common_name_type) { create(:name_type, name: "common") }
    let!(:vernacular_name_type) { create(:name_type, name: "vernacular") }
    let!(:scientific_name_type) { create(:name_type, name: "scientific", scientific: true) }

    it "returns only the common name type" do
      options = NameType.common_only_options
      expect(options.length).to eq 1
    end

    it "returns the common name type with correct structure" do
      options = NameType.common_only_options
      expect(options.first).to eq ["common", common_name_type.id, { class: "other" }]
    end

    it "does not include vernacular name types" do
      options = NameType.common_only_options
      names = options.map(&:first)
      expect(names).not_to include("vernacular")
    end

    it "does not include scientific name types" do
      options = NameType.common_only_options
      names = options.map(&:first)
      expect(names).not_to include("scientific")
    end

    it "is case-insensitive for 'common'" do
      # Create a name type with different case
      common_uppercase = create(:name_type, name: "COMMON")

      options = NameType.common_only_options
      names = options.map(&:first)

      expect(names).to include("common")
      expect(names).to include("COMMON")
    end
  end
end
