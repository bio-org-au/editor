# frozen_string_literal: true

require "test_helper"

class AuthorNameAndOrAbbrevTest < ActiveSupport::TestCase
  test "returns name and abbrev separated by pipe when both present" do
    author = authors(:bentham)
    assert_equal "#{author.name} | #{author.abbrev}", author.name_and_or_abbrev
  end

  test "returns name only when abbrev is blank" do
    author = authors(:has_name_only)
    assert_nil author.abbrev
    assert_equal author.name, author.name_and_or_abbrev
  end

  test "returns abbrev only when name is blank" do
    author = authors(:has_abbrev_only)
    assert_nil author.name
    assert_equal author.abbrev, author.name_and_or_abbrev
  end
end
