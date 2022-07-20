# frozen_string_literal: true

require "test_helper"

# Single author model test.
class UpdateDistributionTest < ActiveSupport::TestCase
  test "update distribution" do
    trel = tree_elements(:red_gum_in_taxonomy)
    trel = update_null_dist_to_null_value(trel)
    trel = update_null_profile_to_non_null_disordered_dist(trel)
    trel = remove_dist_leaving_comment(trel)
    trel = update_null_dist_to_valid_dist(trel, "WA, NSW (naturalised)")
    update_dist_to_valid_dist(trel, "NSW,,")
  end

  def update_null_dist_to_null_value(trel)
    new_dist = nil
    assert_nil(trel.profile, "Expect no profile to start this test")
    assert_nil(trel.distribution, "Expect no profile distribution to start this test")
    updated_by = trel.updated_by
    updated_at = trel.updated_at
    _message, _refresh = trel.update_distribution(new_dist, "d2nulluser")
    return_te = confirm_unchanged_nil(trel, updated_at, updated_by, "d2nulluser")
  end

  def confirm_unchanged_nil(trel, updated_at, updated_by, agent)
    te_changed = Tree::Element.find(trel.id)
    assert_nil(te_changed.distribution_value, "Update distribution, update null to null - value is not nil error")
    assert_equal(updated_at, te_changed.updated_at)
    assert_equal(updated_by, te_changed.updated_by)
    assert_not_equal(agent, te_changed.updated_by)
    te_changed
  end

  # NOTE: the new distribution is deliberately in the wrong order
  def update_null_profile_to_non_null_disordered_dist(trel)
    tag = "update_null_profile_to_non_null_dist"
    new_dist = "NSW, WA"
    assert_nil(trel.profile, "Expect no profile to start #{tag} test")
    assert_nil(trel.distribution, "Expect no profile distribution to start #{tag} test")
    message, refresh = trel.update_distribution(new_dist, "dist user")
    assert_match(/Distribution added to .* profile/, message, "Wrong message '#{message}' for #{tag}")
    assert(refresh, "Expect refresh for #{tag}")
    return_te = confirm_changed(new_dist, trel, tag)
  end

  def confirm_changed(new_dist, trel, tag)
    te_changed = Tree::Element.find(trel.id)
    assert_equal(new_dist.split(",").collect(&:strip).sort.join(", "),
                 te_changed.distribution_value.split(",").collect(&:strip).sort.join(", "),
                 "Expected sorted distributions to be equal for #{tag}")
    assert_not_equal(new_dist, te_changed.distribution_value,
                     "Expected unsorted distributions to be unequal for #{tag}")
    te_changed
  end

  # NOTE: the new distribution is deliberately in the wrong order
  def remove_dist_leaving_comment(trel)
    tag = "remove_dist_leaving_comment"
    new_dist = ""
    assert_not_nil(trel.profile, "Expect profile to start #{tag} test")
    assert_not_nil(trel.distribution,
                   "Expect profile distribution to start #{tag} test")
    original_updated_by = trel.updated_by
    original_updated_at = trel.updated_at
    message, refresh = trel.update_distribution(new_dist, "rdlcuser")
    te_changed = Tree::Element.find(trel.id)
    assert_match(/Distribution removed/, message,
                 "Wrong message '#{message}' for #{tag}")
    assert(refresh, "Expected refresh for #{tag}")
    assert_nil(te_changed.distribution_value,
               "Expected no distribution for #{tag}")
    assert_nil(te_changed.distribution_value)
    assert_not_equal(original_updated_at, te_changed.updated_at)
    assert_not_equal(original_updated_by, te_changed.updated_by)
    assert_equal("rdlcuser", te_changed.updated_by)
    te_changed
  end

  def update_null_dist_to_valid_dist(trel, new_dist)
    tag = "update_null_dist_to_valid_dist"
    original_updated_by = trel.updated_by
    original_updated_at = trel.updated_at
    message, refresh = trel.update_distribution(new_dist, "dnd2vduser")
    te_changed = Tree::Element.find(trel.id)
    assert_match(/Distribution added to a fresh profile/i,
                 message, "Unexpected message '#{message}' for #{tag}")
    assert(refresh, "Expected refresh for #{tag}")
    assert_equal(new_dist, te_changed.distribution_value,
                 "Expected distribution to be changed for #{tag}")
    assert_not_equal(original_updated_at, te_changed.updated_at)
    assert_not_equal(original_updated_by, te_changed.updated_by)
    assert_equal("dnd2vduser", te_changed.updated_by)
    te_changed
  end

  def update_dist_to_valid_dist(trel, new_dist)
    tag = "update_dist_to_valid_dist"
    original_updated_by = trel.updated_by
    original_updated_at = trel.updated_at
    message, refresh = trel.update_distribution(new_dist, "ud2vduser")
    te_changed = Tree::Element.find(trel.id)
    assert_match(/Distribution changed/i,
                 message, "Unexpected message '#{message}' for #{tag}")
    assert(refresh, "Expected refresh for #{tag}")
    assert_equal(new_dist.sub(/,,*$/, ""), te_changed.distribution_value,
                 "Expected distribution to be add for #{tag}")
    assert_not_equal(original_updated_at, te_changed.updated_at)
    assert_not_equal(original_updated_by, te_changed.updated_by)
    assert_equal("ud2vduser", te_changed.updated_by)
    te_changed
  end

  def show_tede(trel)
    puts "TEDE: #{trel.distribution_value}"
    Tree::Element::DistributionEntry.where(tree_element_id: trel.id)
                                    .joins(:dist_entry).order("sort_order").each { |tede| puts(tede.show) }
  end
end
