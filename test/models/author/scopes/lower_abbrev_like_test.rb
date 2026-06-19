# frozen_string_literal: true

require "test_helper"

class AuthorScopeLowerAbbrevLikeTest < ActiveSupport::TestCase
  setup do
    @author = authors(:bentham)
  end

  test "lower_abbrev_like returns authors whose abbrev matches a wildcard pattern" do
    results = Author.lower_abbrev_like("Benth*")
    assert_includes results, @author
  end

  test "lower_abbrev_like is case-insensitive" do
    results = Author.lower_abbrev_like("benth*")
    assert_includes results, @author
  end

  test "lower_abbrev_like excludes authors whose abbrev does not match" do
    results = Author.lower_abbrev_like("benth*")
    refute_includes results, authors(:haeckel)
  end
end
