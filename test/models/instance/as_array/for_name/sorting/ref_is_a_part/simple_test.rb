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

# Single instance model test.
class InstanceAsArrayForNameSortingRefIsAPartTest < ActiveSupport::TestCase
  test "instance as array for name sorting ref is a part" do
    name = names(:metrosideros_costata)
    part_instance = instances(:some_part_to_do_with_metrosideros_costata)
    i = Instance::AsArray::ForName.new(name)
    assert i.results.instance_of?(Array),
           "InstanceAsArray::ForName should produce an array."
    assert i.results[4].id == part_instance.id,
           "Instance for the ref of type part should be fifth entry in order."
  end
end
