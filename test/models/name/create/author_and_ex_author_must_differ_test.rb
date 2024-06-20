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

# Single name model test.
class AuthorExAuthorMustDifferOnCreateTest < ActiveSupport::TestCase
  setup do
    @name = Name.new
    @name.namespace = namespaces(:apni)
    @name.name_element = "test for author and ex-author"
    @name.name_type = name_types(:scientific)
    @name.name_rank = name_ranks(:species)
    @name.name_status = name_statuses(:legitimate)
    @name.parent = names(:a_genus)
    @name.name_path = 'must_not_by_empty'
    @name.created_by = "fred"
    @name.updated_by = "fred"
  end

  test "author and ex author are different" do
    part1
    part2
  end

  def part1
    assert @name.valid?,
           "New name should be valid without authors.
           Errors: #{@name.errors.full_messages.join('; ')}"
    @name.author = authors(:bentham)
    assert @name.valid?,
           "New name should be valid with an author.
           Errors: #{@name.errors.full_messages.join('; ')}"
    @name.ex_author = authors(:joe)
  end

  def part2
    assert @name.valid?,
           "New name should be valid with an ex-author.
           Errors: #{@name.errors.full_messages.join('; ')}"
    @name.ex_author = authors(:bentham)
    assert_not @name.valid?,
               "New name should not be valid with the same author and ex-author"
    assert_equal @name.errors.full_messages.first,
                 "The ex-author cannot be the same as the author.",
                 "Wrong error message."
  end
end
