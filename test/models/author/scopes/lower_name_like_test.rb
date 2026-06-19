# frozen_string_literal: true

require "test_helper"

class AuthorScopeLowerNameLikeTest < ActiveSupport::TestCase
  setup do
    @author = authors(:haeckel)
  end

  test "lower_name_like returns authors whose name matches a wildcard pattern" do
    results = Author.lower_name_like("Haeckel*")
    assert_includes results, @author
  end

  test "lower_name_like is case-insensitive" do
    results = Author.lower_name_like("haeckel*")
    assert_includes results, @author
  end

  test "lower_name_like excludes authors whose name does not match" do
    results = Author.lower_name_like("haeckel*")
    refute_includes results, authors(:bentham)
  end
end
