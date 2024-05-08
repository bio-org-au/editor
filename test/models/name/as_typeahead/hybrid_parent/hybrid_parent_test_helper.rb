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

def hybrid_parent_suggestions_should_include(suggestions,
                                             given_rank_name,
                                             expected_rank_name)
  re = Regexp.quote(expected_rank_name)
  assert(
    suggestions.collect do |h|
      h[:value].split(/ *\| */).second =~ /#{re}/ ? 1 : 0
    end.sum.positive?,
    "suggestions for #{given_rank_name} should
    include #{expected_rank_name} [caller: #{caller[1]}]"
  )
end

def hybrid_parent_suggestions_should_not_include(suggestions,
                                                 given_rank_name,
                                                 unexpected_rank_name)
  re = Regexp.quote(unexpected_rank_name)
  assert_not(suggestions.collect do |h|
    h[:value].split(/ *\| */).second =~ /\s#{re}/ ? 1 : 0
  end.sum.positive?,
             "suggestions for #{given_rank_name} should not
             include #{unexpected_rank_name}[caller: #{caller[1]}]")
end

def hybrid_parent_suggestions_should_only_include(
  suggs, given_rank, expected_rank_names
)
  NameRank.all.sort_by(&:sort_order).each do |rank|
    if expected_rank_names.include?(rank.name)
      hybrid_parent_suggestions_should_include(suggs, given_rank, rank.name)
    else
      hybrid_parent_suggestions_should_not_include(suggs, given_rank, rank.name)
    end
  end
end


def show(suggestions)
  suggestions.each { |s| print("#{s[:value]}\n") }
end
