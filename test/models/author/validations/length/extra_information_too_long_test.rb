# frozen_string_literal: true

#   Copyright 2025 Australian National Botanic Gardens
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

# Single author model test.
class AuthorExtraInformationTooLongTest < ActiveSupport::TestCase

  def setup
    @max = 255
  end

  test "author extra information too long test" do
    author = authors(:joe)
    assert author.valid?, "Author should be valid to start"
    author.extra_information = "X" * @max 
    assert author.valid?, "Author should be valid with extra information #{@max} chars long"
    assert author.save!, "Author should save"
    author.extra_information = "X" * (@max + 1)
    assert_not author.valid?, "Author should not be valid with extra information #{@max + 1} chars long"
  end
end
