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

# Name status options test.
class NameStatusNameForInstanceDisplaySimpleTest < ActiveSupport::TestCase
  test "simple" do
    NameStatus.all.each do |ns|
      case ns.name
      when "legitimate"
        assert ns.name_for_instance_display.blank?
      when "[n/a]"
        assert ns.name_for_instance_display.blank?
      else
        assert_match ns.name, ns.name_for_instance_display
      end
    end
  end
end
