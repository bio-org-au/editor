# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require "test_helper"

# Instance tests.  Not yet split into single files.
class InstanceATest < ActiveSupport::TestCase
  test "britten_created_angophora_costata should be a standalone instance" do
    britten_instance =
      instances(:britten_created_angophora_costata)
    assert britten_instance.type_of_instance == "Standalone",
           "Instance should be Standalone."
  end

  test "gaertner_created_metrosideros_costata should be standalone instance" do
    gaertner_instance =
      instances(:gaertner_created_metrosideros_costata)
    assert gaertner_instance.type_of_instance == "Standalone",
           "Instance should be Standalone."
  end

  test "metrosideros_costata_is_basionym_of_angophora_costata shd b rel inst" do
    metrosideros_instance =
      instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    assert metrosideros_instance.type_of_instance == "Synonymy",
           "Instance should be Synonymy."
  end

  test "rusty_gum_is_a_common_name_of_angophora_costata unpub cit instance" do
    rusty_gum_instance =
      instances(:rusty_gum_is_a_common_name_of_angophora_costata)
    assert rusty_gum_instance.type_of_instance == "Unpublished citation",
           "Instance should be Unpublished citation."
  end

  test "britten_created_angophora_costata should be valid" do
    britten_instance = instances(:britten_created_angophora_costata)
    assert britten_instance.valid?,
           "should be valid; errors:
           #{britten_instance.errors.full_messages.join(';')}"
  end

  test "gaertner_created_metrosideros_costata should be valid" do
    instance = instances(:gaertner_created_metrosideros_costata)
    assert instance.valid?,
           "should be valid; errors: #{instance.errors.full_messages.join(';')}"
  end

  test "rusty_gum_is_a_common_name_of_angophora_costata should be valid" do
    instance = instances(:rusty_gum_is_a_common_name_of_angophora_costata)
    assert instance.valid?,
           "should be valid; errors: #{instance.errors.full_messages.join(';')}"
  end

  test "ref of relationship syn inst match ref of cited by instance" do
    relationship_instance =
      instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    assert_not relationship_instance.reference_id ==
               references(:handbook_of_the_vascular_plants_of_sydney)
    relationship_instance.reference_id =
      references(:handbook_of_the_vascular_plants_of_sydney).id
    assert_not relationship_instance.valid?,
               "should not be valid"
  end

  test "unpub cit invalid if its inst ref does not match cited by inst ref" do
    instance = instances(:invalid_unpublished_citation_with_unmatched_reference)
    assert instance.relationship?, "Should be a relationship instance."
    assert instance.unpublished_citation?, "Should be an unpublished citation."
    assert_not_nil instance.reference.id, "Should have a reference."
    assert_equal instance.this_is_cited_by.class,
                 Instance,
                 "Should cite an instance."
    assert_not_nil instance.this_is_cited_by.standalone?,
                   "Should point to standalone instance."
    assert_not instance.reference_id == instance.this_is_cited_by.reference_id,
               "Core test condition: refs should not match."
    assert_not instance.valid?, "should not be valid"
  end

  test "name of synonymy instance matches the name of the instance it cites" do
    synonymy_instance =
      instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    assert_not synonymy_instance.name_id == names(:angophora_costata)
    synonymy_instance.name_id = names(:angophora_costata).id
    assert_not synonymy_instance.valid?, "should not be valid"
  end
end
