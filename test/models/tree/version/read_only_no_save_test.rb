# frozen_string_literal: true

require "test_helper"

# Single author model test.
class ReadOnlyNoSaveTest < ActiveSupport::TestCase

  test "saves" do
    tree_version_save 
    tree_draft_version_save 
  end

  def tree_version_save
    ron = tree_versions(:ron_draft_version)
    assert_raises(Exception) {ron.save!}
  end

  def tree_draft_version_save
    ron_as_draft = Tree::DraftVersion.find(tree_versions(:ron_draft_version).id)
    assert_raises(Exception) {ron_as_draft.save!}
  end 
end
