require "rails_helper"

RSpec.describe InstancesHelper, type: :helper do
  describe "#tab_for_instance_record" do
    context "for invalid arguments" do
      it "raises an error" do
        expect { helper.tab_for_instance_record }.to raise_error(ArgumentError)
      end
    end

    context "passing a known tab" do
      it "returns the tab" do
        %w[tab_synonymy
           tab_synonymy_for_profile_v2
           tab_unpublished_citation
           tab_unpublished_citation_for_profile_v2
           tab_classification
           tab_copy_to_new_reference].each do |tab|
          expect(helper.tab_for_instance_record(tab)).to eq tab
        end
      end
    end

    context "passing an unknown tab" do
      it "returns tab_empty" do
        expect(helper.tab_for_instance_record("unknown_tab")).to eq "tab_empty"
      end
    end
  end

  describe "#tab_for_iapo_concept_record" do
    let(:tabs_to_offer) { %w[tab_synonymy tab_classification tab_copy_to_new_reference] }

    before { assign(:tabs_to_offer, tabs_to_offer) }

    context "for invalid arguments" do
      it "raises an error" do
        expect { helper.tab_for_iapo_concept_record }.to raise_error(ArgumentError)
      end
    end

    context "passing a known tab" do
      let(:tabs_to_offer) do
        %w[tab_synonymy
           tab_synonymy_for_profile_v2
           tab_unpublished_citation
           tab_unpublished_citation_for_profile_v2
           tab_classification
           tab_copy_to_new_reference
           tab_batch_loader_2]
      end

      it "returns the tab" do
        %w[tab_synonymy
           tab_synonymy_for_profile_v2
           tab_unpublished_citation
           tab_unpublished_citation_for_profile_v2
           tab_classification
           tab_copy_to_new_reference
           tab_batch_loader_2].each do |tab|
          expect(helper.tab_for_iapo_concept_record(tab)).to eq tab
        end
      end
    end

    context "passing an unknown tab" do
      it "returns tab_empty" do
        expect(helper.tab_for_instance_record("unknown_tab")).to eq "tab_empty"
        expect(helper.tab_for_instance_record("tab_batch_loader_2")).to eq "tab_empty"
      end
    end
  end

  describe "#tab_for_citing_instance_in_name_search" do
    context "for invalid arguments" do
      it "raises an error" do
        expect { helper.tab_for_citing_instance_in_name_search }.to raise_error(ArgumentError)
      end
    end

    context "passing a known tab" do
      it "returns the tab" do
        %w[tab_synonymy
           tab_synonymy_for_profile_v2
           tab_create_unpublished_citation
           tab_unpublished_citation_for_profile_v2].each do |tab|
          expect(helper.tab_for_citing_instance_in_name_search(tab)).to eq tab
        end
      end

      it "returns tab_copy_to_new_reference_na for tab_copy_to_new_reference tab" do
        expect(helper.tab_for_citing_instance_in_name_search("tab_copy_to_new_reference")).to eq "tab_copy_to_new_reference_na"
      end
    end

    context "when the tab is in the copy-related tabs" do
      it "returns 'tab_copy_to_new_reference_na' for 'tab_copy_to_new_reference'" do
        expect(helper.tab_for_citing_instance_in_name_search("tab_copy_to_new_reference")).to eq("tab_copy_to_new_reference_na")
      end

      it "returns 'tab_copy_to_new_reference_na' for 'tab_copy_to_new_profile_v2'" do
        expect(helper.tab_for_citing_instance_in_name_search("tab_copy_to_new_profile_v2")).to eq("tab_copy_to_new_reference_na")
      end
    end

    context "when the tab is not recognized" do
      it "returns 'tab_empty' for an unrecognized tab" do
        expect(helper.tab_for_citing_instance_in_name_search("tab_unknown")).to eq("tab_empty")
      end

      it "returns 'tab_empty' for a nil tab" do
        expect(helper.tab_for_citing_instance_in_name_search(nil)).to eq("tab_empty")
      end

      it "returns 'tab_empty' for an empty string tab" do
        expect(helper.tab_for_citing_instance_in_name_search("")).to eq("tab_empty")
      end
    end
  end
end
