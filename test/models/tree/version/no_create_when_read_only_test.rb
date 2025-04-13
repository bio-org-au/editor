# frozen_string_literal: true

require "test_helper"

# Single author model test.
class NoCreateWhenReadOnlyTest < ActiveSupport::TestCase

  test "no create via service when read only" do
    assert_raises(Exception) {Tree::DraftVersion.create_via_service(trees(:RON).id,
                                          tree_versions(:ron_draft_version),
                                          'draft name',
                                          'draft log entry',
                                          false,
                                          'fred')}
  end 
end
