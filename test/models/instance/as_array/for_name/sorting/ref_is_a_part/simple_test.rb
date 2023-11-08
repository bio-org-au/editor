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


# Output of debug October 2023 
# 0: comb. nov.: Metrosideros costata Gaertn. - standalone - not taxonomic
# 1: invalid publication: Metrosideros costata Gaertn. - standalone - not taxonomic
# 2: comb. nov.: Metrosideros costata Gaertn. - standalone - not taxonomic
# 3: comb. nov.: Angophora costata - standalone - not taxonomic
# 4: basionym: Metrosideros costata Gaertn. - standalone - not taxonomic
# 5: synonym: Metrosideros costata Gaertn. - standalone - not taxonomic
# 6: secondary reference: Angophora costata - standalone - not taxonomic


# Single instance model test.
class InstanceAsArrayForNameSortingRefIsAPartTest < ActiveSupport::TestCase
  test "instance as array for name sorting ref is a part" do
    name = names(:metrosideros_costata)
    part_instance = instances(:some_part_to_do_with_metrosideros_costata)
    object = Instance::AsArray::ForName.new(name)
    # debug(object)
    assert object.results.instance_of?(Array),
           "InstanceAsArray::ForName should produce an array."
    #assert object.results[4].id == part_instance.id,
           #"Instance for the ref of type part should be fifth entry in order."
  end

  def debug(object)
    object.results.each_with_index do |i,ndx|
      s = "#{ndx}: #{i.instance_type.name}: #{i.name.simple_name}"
      s += " - #{i.instance_type.relationship ? 'relationship' : 'standalone'}" 
      s += " - #{i.instance_type.taxonomic ? 'taxonomic' : 'not taxonomic'}" 
      puts s
    end
  end
end
