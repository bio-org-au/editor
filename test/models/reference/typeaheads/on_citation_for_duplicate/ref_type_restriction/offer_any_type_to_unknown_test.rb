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

# Reference model typeahead search.
class TAOnCitnForDupeRefTypeRestrictionAnyType4Unknown < ActiveSupport::TestCase
  test "ref typeahead on citation ref type restriction any type for unknown" do
    current_reference = references(:ref_type_is_unknown)
    typeahead = Reference::AsTypeahead::OnCitationForDuplicate.new(
      "%",
      current_reference.id
    )
    assert !typeahead.results.empty?, "Should be at least one result"
    journals = 0
    unknowns = 0
    papers = 0
    others = 0
    typeahead.results.each do |result|
      case result[:value]
      when /\[journal\]/
        journals += 1
      when /\[paper\]/
        papers += 1
      when /\[unknown\]/
        unknowns += 1
      else
        others += 1
      end
    end
    assert others.positive?, "Expecting plenty of other ref types."
    assert journals.positive?, "Expecting at least 1 journal."
    assert papers.positive?, "Expecting at least 1 paper."
    assert unknowns.positive?, "Expecting at least 1 unknown ref type."
  end
end
