require 'rails_helper'

RSpec.describe Instance::AsCopier, type: :model do
  subject { described_class.new }

  describe "#copy_with_product_reference" do
    context "with invalid arguments" do
      it "raises an error" do
        expect{described_class.new.copy_with_product_reference}.to raise_error(ArgumentError)
      end
    end

    context "with valid arguments" do
      let(:params) { {} }
      let(:username) { "username" }

      let(:reference) { FactoryBot.create(:reference) }
      let(:name_category) { FactoryBot.create(:name_category, name: "other") }
      let(:name_type) { FactoryBot.create(:name_type, cultivar: false, name_category: name_category) }
      let(:name) { FactoryBot.create(:name, name_type: name_type) }
      
      let(:instance) { FactoryBot.create(:instance, reference: reference) }
      let(:instance_citation) { FactoryBot.create(:instance, name: name, reference: reference) }
      
      context "with invalid parameters" do
        it "raises an error for blank reference_id" do
          expect{subject.copy_with_product_reference(params, username)}.to raise_error(RuntimeError, "Need a reference")
        end

        it "raises an error for non-integer reference_id" do
          expect{subject.copy_with_product_reference({reference_id: "a"}, username)}.to raise_error(RuntimeError, "Unrecognized reference id")
        end

        it "raises an error for when a reference does not exists" do
          non_existent_reference_id = reference.id + 1
          expect{subject.copy_with_product_reference({reference_id: non_existent_reference_id}, username)}.to raise_error(RuntimeError, "No such ref")
        end
      end

      context "for valid parameters" do
        let(:instance_type) { FactoryBot.create(:instance_type, name: "another name")}
        let(:params) do
          {
            reference_id: reference.id,
            instance_type_id: instance_type.id,
            draft: true
          }
        end

        subject { described_class.find(instance.id) }

        before do
          subject.multiple_primary_override = true
          subject.duplicate_instance_override = true
        end

        it "creates a copy of the instance" do
          copied_instance = subject.copy_with_product_reference(params,username)
          excluded_attributes = [
            "id", "created_at", "created_by", "updated_at", "instance_type_id",
            "lock_version", "reference_id", "source_id_string", "source_system",
            "updated_at", "updated_by"
          ]
          expect(copied_instance.attributes.except(*excluded_attributes)).to eq(subject.attributes.except(*excluded_attributes))
          expect(copied_instance.class).to eq Instance::AsCopier
        end

        # it "creates a copy of the instance's citations" do
        #   instance.update(cited_by_id: instance_citation.id)
        #   instance.reload
        #   instance_citation.multiple_primary_override = true
        #   subj = described_class.find(instance.id)
        #   subj.multiple_primary_override = true
        #   subj.duplicate_instance_override = true

        #   allow(subj).to receive(:reverse_of_this_is_cited_by).and_return([instance_citation])
        #   # name_category = FactoryBot.create(:name_category, name: "other") 
        #   # name_type = FactoryBot.create(:name_type, cultivar: false, name_category: name_category)
        #   # name = FactoryBot.create(:name, name_type: name_type)


        #   #allow(subject).to receive(:reverse_of_this_is_cited_by).and_return(instance_citation)
        #   debugger
        #   copied_instance = subj.copy_with_product_reference(params,username)
        # end
      end
    end
  end
end