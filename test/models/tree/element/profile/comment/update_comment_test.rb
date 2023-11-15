# frozen_string_literal: true

require "test_helper"

# Single author model test.
class UpdateCommentTest < ActiveSupport::TestCase
  def setup
    @te = tree_elements(:red_gum_in_taxonomy)
  end

  test "update comment" do
    update_null_profile_to_non_null_comment
    update_non_null_comment_to_null_value
    update_null_comment_to_null_value
    update_null_comment_to_non_null_value
    update_non_null_comment_to_non_null_value
    update_non_null_comment_to_unchanged_value
  end

  def update_null_profile_to_non_null_comment
    new_comment = "comment for where no profile exists"
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    assert_nil(@te.profile, "Expect no profile to start this test")
    assert_nil(@te.comment, "Expect no profile comment to start this test")
    @te.update_comment(new_comment, "np2nncuser")
    te_changed = Tree::Element.find(@te.id)
    assert_equal(te_changed.comment_value, new_comment)
    assert_not_equal(original_updated_at, te_changed.updated_at)
    assert_not_equal(original_updated_by, te_changed.updated_by)
    assert_equal("np2nncuser", te_changed.updated_by)
    te_changed
  end

  def update_null_comment_to_non_null_value
    new_comment = "comment for where none exists"
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    assert_nil(@te.profile, "Expect no profile to start this test")
    assert_nil(@te.comment, "Expect no profile comment to start this test")
    @te.update_comment(new_comment, "unc2nnvuser")
    te_changed = Tree::Element.find(@te.id)
    assert_equal(te_changed.comment_value, new_comment)
    assert_not_equal(original_updated_at, te_changed.updated_at)
    assert_not_equal(original_updated_by, te_changed.updated_by)
    assert_equal("unc2nnvuser", te_changed.updated_by)
    te_changed
  end

  def update_non_null_comment_to_null_value
    new_comment = nil
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    assert_not_nil(@te.profile, "Expect profile to exist to start this test")
    assert_not_nil(@te.comment, "Expect profile comment to exist to start this test")
    @te.update_comment(new_comment, "unnc2nvuser")
    te_changed = Tree::Element.find(@te.id)
    assert_nil(te_changed.comment_value)
    assert_not_equal(original_updated_at, te_changed.updated_at)
    assert_not_equal(original_updated_by, te_changed.updated_by)
    assert_equal("unnc2nvuser", te_changed.updated_by)
    te_changed
  end

  def update_null_comment_to_null_value
    new_comment = nil
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    assert_nil(@te.profile, "Expect no profile to start this test")
    assert_nil(@te.comment, "Expect profile comment to be null to start this test")
    @te.update_comment(new_comment, "nncuser")
    te_changed = Tree::Element.find(@te.id)
    assert_nil(te_changed.comment_value)
    assert_equal(original_updated_at, te_changed.updated_at)
    assert_equal(original_updated_by, te_changed.updated_by)
    assert_not_equal("nncuser", te_changed.updated_by)
    te_changed
  end

  def update_non_null_comment_to_non_null_value
    new_comment = "non-null value"
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    assert_not_nil(@te.profile, "Expect profile to exist to start this test")
    assert_not_nil(@te.comment, "Expect profile comment to exist to start this test")
    @te.update_comment(new_comment, "nncuser")
    te_changed = Tree::Element.find(@te.id)
    assert_equal(new_comment, te_changed.comment_value)
    assert_not_equal(original_updated_at, te_changed.updated_at)
    assert_not_equal(original_updated_by, te_changed.updated_by)
    assert_equal("nncuser", te_changed.updated_by)
    te_changed
  end

  def update_non_null_comment_to_unchanged_value
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    assert_not_nil(@te.profile, "Expect profile to exist to start this test")
    assert_not_nil(@te.comment, "Expect profile comment to exist to start this test")
    new_comment = @te.comment_value
    @te.update_comment(new_comment, "unnc2uvuser")
    te_changed = Tree::Element.find(@te.id)
    assert_equal(new_comment, te_changed.comment_value)
    assert_equal(original_updated_at, te_changed.updated_at)
    assert_equal(original_updated_by, te_changed.updated_by)
    assert_not_equal("unnc2uvuser", te_changed.updated_by)
    te_changed
  end
end
