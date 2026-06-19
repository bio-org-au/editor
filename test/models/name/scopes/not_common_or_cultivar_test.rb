# frozen_string_literal: true

require "test_helper"

class NameScopeNotCommonOrCultivarTest < ActiveSupport::TestCase
  setup do
    @scientific = names(:a_species)
    @common     = names(:rusty_gum)
    @cultivar   = names(:a_cultivar)
  end

  test "not_common_or_cultivar includes scientific names" do
    assert_includes Name.not_common_or_cultivar, @scientific
  end

  test "not_common_or_cultivar excludes common names" do
    refute_includes Name.not_common_or_cultivar, @common
  end

  test "not_common_or_cultivar excludes cultivar names" do
    refute_includes Name.not_common_or_cultivar, @cultivar
  end
end
