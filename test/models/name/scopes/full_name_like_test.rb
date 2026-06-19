# frozen_string_literal: true

require "test_helper"

class NameScopeFullNameLikeTest < ActiveSupport::TestCase
  setup do
    @name = names(:angophora_costata)
  end

  test "full_name_like returns names matching a prefix" do
    assert_includes Name.full_name_like("Angophora costata"), @name
  end

  test "full_name_like is case-insensitive" do
    assert_includes Name.full_name_like("angophora costata"), @name
  end

  test "full_name_like supports wildcard via asterisk" do
    assert_includes Name.full_name_like("Angoph*"), @name
  end

  test "full_name_like excludes names that do not match" do
    refute_includes Name.full_name_like("Triodia"), @name
  end
end
