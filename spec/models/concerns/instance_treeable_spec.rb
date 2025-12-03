# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InstanceTreeable do
  describe '#in_published_trees' do
    context 'when instance is in a single published tree' do
      let(:instance) { create(:instance) }
      let(:tree) { create(:tree, name: 'Published Tree', is_read_only: false) }
      let(:tree_version) { create(:tree_version, tree: tree) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns instances in published trees' do
        result = instance.in_published_trees

        expect(result).to be_present
        expect(result.first.id).to eq(instance.id)
        expect(result.first[:name]).to eq('Published Tree')
      end
    end

    context 'when instance is only in read-only trees' do
      let(:instance) { create(:instance) }
      let(:tree) { create(:tree, name: 'Read Only Tree', is_read_only: false) }
      let(:tree_version) { create(:tree_version, tree: tree) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id, is_read_only: true)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/readonly/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns empty result' do
        result = instance.in_published_trees
        expect(result).to be_empty
      end
    end

    context 'when instance is not in any trees' do
      let(:instance) { create(:instance) }

      it 'returns empty result' do
        result = instance.in_published_trees
        expect(result).to be_empty
      end
    end

    context 'when multiple published trees contain the instance' do
      let(:instance) { create(:instance) }
      let(:tree_1) { create(:tree, name: 'Published Tree', is_read_only: false) }
      let(:tree_2) { create(:tree, name: 'Second Published Tree', is_read_only: false) }
      let(:tree_version_1) { create(:tree_version, tree: tree_1) }
      let(:tree_version_2) { create(:tree_version, tree: tree_2) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree_1.update!(current_tree_version_id: tree_version_1.id)
        tree_2.update!(current_tree_version_id: tree_version_2.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version_1.id,
          element_link: "test/tree1/#{tree_element.id}",
          taxon_id: tree_element.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version_2.id,
          element_link: "test/tree2/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns all published trees containing the instance' do
        result = instance.in_published_trees

        expect(result.size).to eq(2)
        tree_names = result.map { |r| r[:name] }
        expect(tree_names).to include('Published Tree', 'Second Published Tree')
      end
    end

    context 'when instance is in both read-only and non-read-only trees' do
      let(:instance) { create(:instance) }
      let(:readonly_tree) { create(:tree, name: 'Read Only Tree', is_read_only: false) }
      let(:editable_tree) { create(:tree, name: 'Editable Tree', is_read_only: false) }
      let(:readonly_version) { create(:tree_version, tree: readonly_tree) }
      let(:editable_version) { create(:tree_version, tree: editable_tree) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        readonly_tree.update!(current_tree_version_id: readonly_version.id, is_read_only: true)
        editable_tree.update!(current_tree_version_id: editable_version.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: readonly_version.id,
          element_link: "test/readonly/#{tree_element.id}",
          taxon_id: tree_element.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: editable_version.id,
          element_link: "test/editable/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns only non-read-only trees' do
        result = instance.in_published_trees

        expect(result.length).to eq(1)
        expect(result.first[:name]).to eq('Editable Tree')
      end
    end
  end
end
