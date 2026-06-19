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

      it 'returns the instance with tree details' do
        result = instance.in_published_trees

        expect(result).to be_present
        expect(result.first.id).to eq(instance.id)
        expect(result.first[:tree_name]).to eq('Published Tree')
        expect(result.first[:excluded]).to eq(tree_element.excluded)
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
        tree_names = result.map { |r| r[:tree_name] }
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
        expect(result.first[:tree_name]).to eq('Editable Tree')
      end
    end
  end

  describe '#in_any_local_tree_ids?' do
    let(:instance) { create(:instance) }

    context 'when tree_ids is blank' do
      it 'returns false for empty array' do
        expect(instance.in_any_local_tree_ids?([])).to eq false
      end

      it 'returns false for nil' do
        expect(instance.in_any_local_tree_ids?(nil)).to eq false
      end
    end

    context 'when instance is in one of the provided trees' do
      let(:tree) { create(:tree, is_read_only: false) }
      let(:tree_version) { create(:tree_version, tree: tree, draft_name: "In Tree Draft") }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/in_tree/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns true' do
        expect(instance.in_any_local_tree_ids?([tree.id])).to eq true
      end

      it 'returns true when tree is among multiple tree_ids' do
        other_tree = create(:tree)
        expect(instance.in_any_local_tree_ids?([other_tree.id, tree.id])).to eq true
      end
    end

    context 'when instance is not in any of the provided trees' do
      let(:tree) { create(:tree, is_read_only: false) }
      let(:other_tree) { create(:tree) }
      let(:tree_version) { create(:tree_version, tree: tree, draft_name: "Not In Draft") }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/not_in/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns false' do
        expect(instance.in_any_local_tree_ids?([other_tree.id])).to eq false
      end
    end

    context 'when instance is not in any trees at all' do
      let(:tree) { create(:tree) }

      it 'returns false' do
        expect(instance.in_any_local_tree_ids?([tree.id])).to eq false
      end
    end

    context 'when tree version is not current' do
      let(:tree) { create(:tree, is_read_only: false) }
      let(:old_tree_version) { create(:tree_version, tree: tree, draft_name: "Old Draft") }
      let(:current_tree_version) { create(:tree_version, tree: tree, draft_name: "Current Draft") }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: current_tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: old_tree_version.id,
          element_link: "test/old/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns false because instance is only in old version' do
        expect(instance.in_any_local_tree_ids?([tree.id])).to eq false
      end
    end
  end
end
