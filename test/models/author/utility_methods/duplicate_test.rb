# frozen_string_literal: true

require "test_helper"

class AuthorDuplicatePredicateTest < ActiveSupport::TestCase
  setup do
    @duplicate     = authors(:schlechter_a_duplicate)
    @non_duplicate = authors(:schlechter_not_a_duplicate)
  end

  test "duplicate? returns true when duplicate_of_id is set" do
    assert_predicate @duplicate, :duplicate?
  end

  test "duplicate? returns false when duplicate_of_id is nil" do
    assert_not @non_duplicate.duplicate?
  end
end
