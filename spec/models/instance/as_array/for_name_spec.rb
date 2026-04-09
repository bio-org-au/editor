# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instance::AsArray::ForName, type: :model do
  let(:name) { create(:name) }
  let(:primary_type) { create(:instance_type, standalone: true, primary_instance: true, relationship: false) }
  let(:secondary_type) { create(:instance_type, standalone: true, primary_instance: false, relationship: false) }
  let(:relationship_type) { create(:instance_type, standalone: false, primary_instance: false, relationship: true) }

  def create_instance(name:, draft:, author_name:, year:, iso_date:, primary: false)
    author = create(:author, name: author_name)
    reference = create(:reference, author: author, year: year, iso_publication_date: iso_date)
    instance_type = primary ? primary_type : secondary_type
    create(:instance, name: name, reference: reference, instance_type: instance_type, draft: draft)
  end

  def create_relationship_instance(name:, draft:, author_name:, year:, iso_date:, cited_by_instance:)
    author = create(:author, name: author_name)
    reference = create(:reference, author: author, year: year, iso_publication_date: iso_date)
    instance = build(:instance, name: name, reference: reference, instance_type: relationship_type, draft: draft,
                     this_cites: cited_by_instance, this_is_cited_by: cited_by_instance)
    instance.save!(validate: false)
    instance
  end

  describe "sorting draft instances" do
    let!(:non_draft_old) { create_instance(name: name, draft: false, author_name: "Alpha", year: 1990, iso_date: "1990", primary: true) }
    let!(:non_draft_new) { create_instance(name: name, draft: false, author_name: "Beta", year: 2000, iso_date: "2000") }
    let!(:draft_by_gamma) { create_instance(name: name, draft: true, author_name: "Gamma", year: 2020, iso_date: "2020") }
    let!(:draft_by_zeta) { create_instance(name: name, draft: true, author_name: "Zeta", year: 2021, iso_date: "2021") }

    subject { described_class.new(name) }

    let(:standalone_results) { subject.results.select { |r| r.is_a?(Instance) && r.standalone? } }
    let(:draft_results) { standalone_results.select(&:draft?) }
    let(:non_draft_results) { standalone_results.reject(&:draft?) }

    it "sorts all instances chronologically by year" do
      years = standalone_results.map { |i| i.reference.year.to_i }

      expect(years).to eq([1990, 2000, 2020, 2021])
    end

    it "sorts draft instances chronologically by year" do
      years = draft_results.map { |i| i.reference.year.to_i }

      expect(years).to eq([2020, 2021])
    end

    it "sorts non-draft instances by year ascending" do
      years = non_draft_results.map { |i| i.reference.year.to_i }

      expect(years).to eq([1990, 2000])
    end
  end

  describe "draft instances with same year as non-drafts" do
    let!(:non_draft_2020) { create_instance(name: name, draft: false, author_name: "Alpha", year: 2020, iso_date: "2020", primary: true) }
    let!(:draft_2020) { create_instance(name: name, draft: true, author_name: "Beta", year: 2020, iso_date: "2020") }

    subject { described_class.new(name) }

    let(:standalone_results) { subject.results.select { |r| r.is_a?(Instance) && r.standalone? } }

    it "places non-draft before draft when they have the same year" do
      expect(standalone_results.map(&:id)).to eq([non_draft_2020.id, draft_2020.id])
    end
  end

  describe "undated draft instances" do
    let!(:non_draft) { create_instance(name: name, draft: false, author_name: "Alpha", year: 2000, iso_date: "2000", primary: true) }
    let!(:dated_draft) { create_instance(name: name, draft: true, author_name: "Beta", year: 2020, iso_date: "2020") }
    let!(:undated_draft_zeta) { create_instance(name: name, draft: true, author_name: "Zeta", year: nil, iso_date: nil) }
    let!(:undated_draft_gamma) { create_instance(name: name, draft: true, author_name: "Gamma", year: nil, iso_date: nil) }

    subject { described_class.new(name) }

    let(:standalone_results) { subject.results.select { |r| r.is_a?(Instance) && r.standalone? } }

    it "places undated drafts after dated drafts" do
      ids = standalone_results.map(&:id)
      dated_draft_idx = ids.index(dated_draft.id)
      undated_draft_zeta_idx = ids.index(undated_draft_zeta.id)
      undated_draft_gamma_idx = ids.index(undated_draft_gamma.id)

      expect(undated_draft_zeta_idx).to be > dated_draft_idx
      expect(undated_draft_gamma_idx).to be > dated_draft_idx
    end

    it "sorts undated drafts alphabetically by author" do
      undated_drafts = standalone_results.select { |i| i.draft? && i.reference.year.nil? }
      author_names = undated_drafts.map { |i| i.reference.author.name }

      expect(author_names).to eq(["Gamma", "Zeta"])
    end
  end

  describe "when there are no draft instances" do
    let!(:instance_old) { create_instance(name: name, draft: false, author_name: "Alpha", year: 1990, iso_date: "1990", primary: true) }
    let!(:instance_new) { create_instance(name: name, draft: false, author_name: "Beta", year: 2000, iso_date: "2000") }

    subject { described_class.new(name) }

    it "sorts by the original multi-field sort order" do
      standalone_results = subject.results.select { |r| r.is_a?(Instance) && r.standalone? }
      years = standalone_results.map { |i| i.reference.year.to_i }

      expect(years).to eq([1990, 2000])
    end
  end

  describe "when all instances are drafts" do
    let!(:draft_by_alpha) { create_instance(name: name, draft: true, author_name: "Alpha", year: 2020, iso_date: "2020") }
    let!(:draft_by_zeta) { create_instance(name: name, draft: true, author_name: "Zeta", year: 2021, iso_date: "2021") }

    subject { described_class.new(name) }

    it "sorts by year chronologically" do
      standalone_results = subject.results.select { |r| r.is_a?(Instance) && r.standalone? }
      years = standalone_results.map { |i| i.reference.year.to_i }

      expect(years).to eq([2020, 2021])
    end
  end

  describe "sorting with both standalone and relationship instances" do
    before do
      allow_any_instance_of(Instance).to receive(:accepted_concept?).and_return(false)
    end

    let!(:standalone_non_draft) { create_instance(name: name, draft: false, author_name: "Beta", year: 2000, iso_date: "2000", primary: true) }
    let!(:standalone_draft_zeta) { create_instance(name: name, draft: true, author_name: "Zeta", year: 2020, iso_date: "2020") }
    let!(:standalone_draft_gamma) { create_instance(name: name, draft: true, author_name: "Gamma", year: 2021, iso_date: "2021") }
    let!(:relationship_non_draft) { create_relationship_instance(name: name, draft: false, author_name: "Alpha", year: 1990, iso_date: "1990", cited_by_instance: standalone_non_draft) }
    let!(:relationship_draft) { create_relationship_instance(name: name, draft: true, author_name: "Delta", year: 2010, iso_date: "2010", cited_by_instance: standalone_non_draft) }

    subject { described_class.new(name) }

    let(:all_instances) { subject.results.select { |r| r.is_a?(Instance) } }
    let(:draft_instances) { all_instances.select(&:draft?) }
    let(:non_draft_instances) { all_instances.reject(&:draft?) }

    it "sorts standalone instances chronologically with non-drafts before drafts in same year" do
      standalone_results = all_instances.select(&:standalone?).uniq(&:id)
      years = standalone_results.map { |i| i.reference.year.to_i }

      expect(years).to eq([2000, 2020, 2021])
    end

    it "includes both standalone and relationship draft instances in draft results" do
      draft_ids = draft_instances.map(&:id)
      expect(draft_ids).to include(standalone_draft_zeta.id)
      expect(draft_ids).to include(standalone_draft_gamma.id)
      expect(draft_ids).to include(relationship_draft.id)
    end

    it "includes both standalone and relationship non-draft instances in non-draft results" do
      non_draft_ids = non_draft_instances.map(&:id)
      expect(non_draft_ids).to include(standalone_non_draft.id)
      expect(non_draft_ids).to include(relationship_non_draft.id)
    end

    it "sorts draft standalone instances chronologically by year" do
      draft_standalones = all_instances.select { |i| i.standalone? && i.draft? }
      years = draft_standalones.map { |i| i.reference.year.to_i }
      expect(years).to eq([2020, 2021])
    end
  end
end
