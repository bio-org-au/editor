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
load "test/models/search/parsed_request/defined_queries/test_runner.rb"

# Single Search model test.
class SearchParsedRequestDefinedQueriesAllTest < ActiveSupport::TestCase
  DEFINED_QUERIES = {
    "references with instances" => "references-name-full-synonymy",
    "references, names, full synonymy" => "references-name-full-synonymy",
    "references + instances" => "references-name-full-synonymy",
    "references with novelties" => "references-with-novelties",
    "references, accepted names for id" => "references-accepted-names-for-id",
    "instance is cited" => "instance-is-cited",
    "instance is cited by" => "instance-is-cited-by",
    "audit" => "audit",
    "activity" => "audit"
  }.freeze

  test "search parsed request defined query all" do
    DEFINED_QUERIES.each do |key, value|
      run_test(key, value)
    end
  end
end
