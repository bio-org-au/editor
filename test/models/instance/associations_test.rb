# frozen_string_literal: true

require "test_helper"

class InstanceAssociationsTest < ActiveSupport::TestCase
  setup do
    @standalone   = instances(:gaertner_created_metrosideros_costata)
    @relationship = instances(:metrosideros_costata_is_basionym_of_angophora_costata)
  end

  test "standalone instance belongs to a name" do
    assert_predicate @standalone.name, :present?
  end

  test "standalone instance belongs to a reference" do
    assert_predicate @standalone.reference, :present?
  end

  test "standalone instance belongs to an instance_type" do
    assert_predicate @standalone.instance_type, :present?
  end

  test "standalone? is true when cites_id and cited_by_id are both nil" do
    assert_predicate @standalone, :standalone?
  end

  test "standalone? is false for a relationship instance" do
    assert_not @relationship.standalone?
  end

  test "relationship instance has a this_cites association" do
    assert_predicate @relationship.this_cites, :present?
  end

  test "relationship instance has a this_is_cited_by association" do
    assert_predicate @relationship.this_is_cited_by, :present?
  end

  test "standalone instance is cited by at least one relationship instance" do
    assert_not_empty @standalone.reverse_of_this_cites
  end
end
