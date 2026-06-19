# frozen_string_literal: true

require "test_helper"

class AuthorKnownUnknownTest < ActiveSupport::TestCase
  setup do
    @unknown_author = authors(:unknown)
    @known_author   = authors(:bentham)
  end

  test "unknown returns true when name is a dash" do
    assert_predicate @unknown_author, :unknown
  end

  test "unknown returns false for a real author name" do
    assert_not @known_author.unknown
  end

  test "known returns false when name is a dash" do
    assert_not @unknown_author.known
  end

  test "known returns true for a real author name" do
    assert_predicate @known_author, :known
  end
end
