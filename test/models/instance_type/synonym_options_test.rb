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

# Instance type options test.
class InstanceTypeSynonymOptionsTest < ActiveSupport::TestCase
  setup do
    options = InstanceType.synonym_options
    assert options.instance_of?(Array), "Should be an array."
    #assert_equal 13, options.size, "Should be 13 of them."
    @names = options.collect(&:first)
    @expected = [
      "alternative name",
      "basionym",
      "doubtful misapplied",
      "doubtful pro parte misapplied",
      "doubtful pro parte taxonomic synonym",
      "doubtful taxonomic synonym",
      "isonym",
      "misapplied",
      "nomenclatural synonym",
      "pro parte misapplied",
      "pro parte taxonomic synonym",
      "pro parte nomenclatural synonym",
      "replaced synonym",
      "taxonomic synonym",
      "trade name"
    ]
  end

  test "instance type synonym options" do
    @expected.each do |expected|
      assert @names.include?(expected),
             "Synonym type options should include #{expected}"
    end
    @names.each do |name|
      assert @expected.include?(name),
             "#{name} is unexpected as a synonym type option"
    end
  end
end
