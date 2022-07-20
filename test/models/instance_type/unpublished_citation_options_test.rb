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
class InstanceTypeUnpublishedCitationOptionsTest < ActiveSupport::TestCase
  setup do
    options = InstanceType.unpublished_citation_options
    assert_equal 7, options.size, "Should be 7 of them."
    @names = options.collect(&:first)
    @expected = ["common name", "orthographic variant", "unsourced doubtful misapplied",
                 "unsourced doubtful pro parte misapplied", "unsourced misapplied", "unsourced pro parte misapplied", "vernacular name"]
  end

  test "instance type unpublished citation options" do
    @expected.each do |expected|
      assert @names.include?(expected),
             "Upub citation instance type options should include #{expected}"
    end
    @names.each do |name|
      assert @expected.include?(name),
             "#{name} is unexpected as an unpub citation type option"
    end
  end
end
