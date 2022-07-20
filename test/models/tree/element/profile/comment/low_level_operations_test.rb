# frozen_string_literal: true

require "test_helper"

# Single author model test.
class LowLevelOperationsTest < ActiveSupport::TestCase
  def setup
    @te = tree_elements(:red_gum_in_taxonomy)
  end

  test "comment key" do
    assert_equal(@te.comment_key, "APC Comment")
  end

  test "profile comment crud" do
    add_comment_where_none_exists
    update_comment
    remove_comment
    add_comment_to_null_profile
  end

  def add_comment_where_none_exists
    new_comment = "comment for where none exists"
    assert_nil(@te.profile, "Expect no profile to start this test")
    assert_nil(@te.comment, "Expect no profile comment to start this test")
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    @te.add_profile_and_comment(new_comment, "cadder")
    assert_not_nil(@te.comment)
    assert_equal(@te.comment_value, new_comment)
    assert_not_equal(original_updated_at, @te.updated_at)
    assert_not_equal(original_updated_by, @te.updated_by)
    assert_equal("cadder", @te.updated_by)
  end

  def update_comment
    new_comment = "updated comment"
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    @te.update_comment(new_comment, "updater")
    te_updated = Tree::Element.find(@te.id)
    assert_equal(new_comment, te_updated.comment_value)
    assert_not_equal(original_updated_at, te_updated.updated_at)
    assert_not_equal(original_updated_by, te_updated.updated_by)
    assert_equal("updater", te_updated.updated_by)
  end

  def remove_comment
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    @te.remove_comment("remover")
    te_no_comment = Tree::Element.find(@te.id)
    assert_nil(te_no_comment.comment)
    assert_nil(te_no_comment.comment_value)
    assert_not_equal(original_updated_at, te_no_comment.updated_at)
    assert_not_equal(original_updated_by, te_no_comment.updated_by)
    assert_equal("remover", te_no_comment.updated_by)
  end

  def add_comment_to_null_profile
    @te.profile = nil
    @te.save!
    original_updated_by = @te.updated_by
    original_updated_at = @te.updated_at
    new_comment = "comment for null profile"
    assert_nil(@te.profile, "Expect empty profile to start this test")
    @te.add_profile_and_comment(new_comment, "commenterx")
    te_with_comment = Tree::Element.find(@te.id)
    assert_not_nil(te_with_comment.comment)
    assert_equal(te_with_comment.comment_value, new_comment)
    assert_equal(te_with_comment.comment_value, new_comment)
    assert_not_equal(original_updated_at, te_with_comment.updated_at)
    assert_not_equal(original_updated_by, te_with_comment.updated_by)
    assert_equal("commenterx", te_with_comment.updated_by)
  end
end
