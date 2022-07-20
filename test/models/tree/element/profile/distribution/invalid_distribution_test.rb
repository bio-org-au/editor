# frozen_string_literal: true

require "test_helper"

# Single author model test.
class InvalidDistributionTest < ActiveSupport::TestCase
  test "invalid distribution" do
    trel = tree_elements(:red_gum_in_taxonomy)
    trel = update_profile_to_invalid_dist(trel, "Wa")
    trel = update_profile_to_invalid_dist(trel, "NSW (native naturalised)")
    trel = update_profile_to_invalid_dist(trel, "wa, nsw, gh")
    trel = update_profile_to_invalid_dist(trel, "VIC")
    trel = update_profile_to_invalid_dist(
      trel,
      "Vic,, NSW",
      /Error: empty distribution value, likely due to an unnecessary comma/i
    )
    update_profile_to_invalid_dist(
      trel,
      ",Vic",
      /Error: empty distribution value, likely due to an unnecessary comma/i
    )
  end

  def update_profile_to_invalid_dist(trel, new_dist, expected_message_re = /Error: Invalid distribution value: /i)
    tag = "update_profile_to_invalid_dist"
    message, refresh = trel.update_distribution(new_dist, "dist user")
    te_changed = Tree::Element.find(trel.id)
    assert_match(expected_message_re,
                 message,
                 "Unexpected message for #{tag} with dist: #{new_dist}")
    assert_not(refresh, "Expected no refresh for #{tag}")
    assert_nil(te_changed.distribution_value,
               "Expected distribution to be unchanged for #{tag}")
    te_changed
  end

  def show_tede(trel)
    puts "TEDE: #{trel.distribution_value}"
    Tree::Element::DistributionEntry.where(tree_element_id: trel.id)
                                    .joins(:dist_entry).order("sort_order").each { |tede| puts(tede.show) }
  end
end
