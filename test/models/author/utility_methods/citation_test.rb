# frozen_string_literal: true

require "test_helper"

class AuthorCitationTest < ActiveSupport::TestCase
  test "citation returns abbrev when present" do
    author = authors(:bentham)
    assert_equal author.abbrev, author.citation
  end

  test "citation returns fallback string when abbrev is nil" do
    author = authors(:has_name_only)
    assert_equal "[no author citation]", author.citation
  end
end
