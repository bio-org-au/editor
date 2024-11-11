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

module Profile
  class ProfileObjectTypeTest < ActiveSupport::TestCase
    def setup
      @profile_object_type = profile_object_type(:profile_text_pot)  # Assuming fixtures are set up
    end

    # Test associations
    test "should have many profile_items" do
      assert_respond_to @profile_object_type, :profile_items
      assert @profile_object_type.profile_items.is_a?(ActiveRecord::Associations::CollectionProxy)
    end

    test "profile_items should use rdf_id as primary key and profile_object_rdf_id as foreign key" do
      assert_equal @profile_object_type.rdf_id, @profile_object_type.profile_items.first.profile_object_rdf_id
    end

    # Test validations
    test "should be valid with valid attributes" do
      assert @profile_object_type.valid?
    end

    test "should not be valid without a name" do
      @profile_object_type.name = nil
      assert_not @profile_object_type.valid?
      assert_includes @profile_object_type.errors[:name], "can't be blank"
    end
  end
end
