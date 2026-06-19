# frozen_string_literal: true

require "test_helper"

class NameScopeNotADuplicateTest < ActiveSupport::TestCase
  setup do
    @original  = names(:a_species)
    @duplicate = names(:a_duplicate_species)
  end

  test "not_a_duplicate scope includes names without duplicate_of_id" do
    assert_includes Name.not_a_duplicate, @original
  end

  test "not_a_duplicate scope excludes names with duplicate_of_id set" do
    refute_includes Name.not_a_duplicate, @duplicate
  end
end
