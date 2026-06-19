# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instance::AsTypeahead::ForChangeName, type: :model do
  let(:name_rank) { create(:name_rank) }
  let(:name_type) { create(:name_type) }
  let(:name) do
    create(:name, full_name: "Acacia dealbata", name_type: name_type, name_rank: name_rank, duplicate_of_id: nil)
  end

  describe "#suggestions" do
    context "when term is blank" do
      it "returns an empty array" do
        result = described_class.new(
          term: "",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        expect(result.suggestions).to eq([])
      end

      it "returns an empty array for nil term" do
        result = described_class.new(
          term: nil,
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        expect(result.suggestions).to eq([])
      end
    end

    context "when term matches a name" do
      before { name }

      it "returns matching names as value/id hashes" do
        result = described_class.new(
          term: "Acacia",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        expect(result.suggestions).to include({ value: "Acacia dealbata", id: name.id })
      end

      it "is case-insensitive" do
        result = described_class.new(
          term: "acacia",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        expect(result.suggestions).to include({ value: "Acacia dealbata", id: name.id })
      end
    end

    context "when term does not match" do
      before { name }

      it "returns an empty array" do
        result = described_class.new(
          term: "Banksia",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        expect(result.suggestions).to eq([])
      end
    end

    context "when name has a different name_type_id" do
      let(:other_name_type) { create(:name_type) }
      let!(:other_name) do
        create(:name, full_name: "Acacia other", name_type: other_name_type, name_rank: name_rank, duplicate_of_id: nil)
      end

      before { name }

      it "excludes names of different type" do
        result = described_class.new(
          term: "Acacia",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        ids = result.suggestions.map { |s| s[:id] }
        expect(ids).not_to include(other_name.id)
      end
    end

    context "when name has a different name_rank_id" do
      let(:other_rank) { create(:name_rank) }
      let!(:other_name) do
        create(:name, full_name: "Acacia different rank", name_type: name_type, name_rank: other_rank, duplicate_of_id: nil)
      end

      before { name }

      it "excludes names of different rank" do
        result = described_class.new(
          term: "Acacia",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        ids = result.suggestions.map { |s| s[:id] }
        expect(ids).not_to include(other_name.id)
      end
    end

    context "when name is excluded by exclude_name_id" do
      before { name }

      it "excludes the current name" do
        result = described_class.new(
          term: "Acacia",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: name.id
        )
        ids = result.suggestions.map { |s| s[:id] }
        expect(ids).not_to include(name.id)
      end
    end

    context "when name is a duplicate" do
      before do
        duplicate_name = create(:name, full_name: "Acacia dup", name_type: name_type, name_rank: name_rank, duplicate_of_id: nil)
        name.update_column(:duplicate_of_id, duplicate_name.id)
      end

      it "excludes duplicate names" do
        result = described_class.new(
          term: "Acacia",
          name_type_id: name_type.id,
          name_rank_id: name_rank.id,
          exclude_name_id: 0
        )
        ids = result.suggestions.map { |s| s[:id] }
        expect(ids).not_to include(name.id)
      end
    end
  end
end
