# frozen_string_literal: true

require "test_helper"

class AuthorScopeNotDuplicateTest < ActiveSupport::TestCase
  setup do
    @non_duplicate = authors(:schlechter_not_a_duplicate)
    @duplicate     = authors(:schlechter_a_duplicate)
  end

  test "not_duplicate scope excludes authors with a duplicate_of_id" do
    results = Author.not_duplicate
    refute_includes results, @duplicate
  end

  test "not_duplicate scope includes authors without a duplicate_of_id" do
    results = Author.not_duplicate
    assert_includes results, @non_duplicate
  end
end
