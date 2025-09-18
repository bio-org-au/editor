# frozen_string_literal: true

require "test_helper"

# Single author model test.
class WritableSaveTest < ActiveSupport::TestCase

  test "saves" do
    tree_version_save 
    tree_draft_version_save 
  end

  def tree_version_save
    apc = tree_versions(:apc_draft_version)
    assert(apc.save!, 'Tree Version should save')
  end

  def tree_draft_version_save
    apc_as_draft = Tree::DraftVersion.find(tree_versions(:apc_draft_version).id)
    assert(apc_as_draft.save!, 'Tree::DraftVersion should save')
  end 
end
