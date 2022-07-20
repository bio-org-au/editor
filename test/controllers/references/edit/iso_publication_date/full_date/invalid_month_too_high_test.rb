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

# Single controller test.
class ReferencesesUpdateInvalidMonthTooHighTest < ActionController::TestCase
  tests ReferencesController

  test "update reference invalid month too high" do
    @request.headers["Accept"] = "application/javascript"
    patch(:update,
          params: { id: references(:simple).id,
                    reference: { "ref_type_id" => ref_types(:book),
                                 "title" => "Some book",
                                 "author_id" => authors(:dash),
                                 "author_typeahead" => "-",
                                 "published" => true,
                                 "parent_typeahead" => @parent_typeahead,
                                 "ref_author_role_id" => ref_author_roles(:author),
                                 "year" => "1999",
                                 "month" => "13",
                                 "day" => "4" } },
          session: { username: "fred",
                     user_full_name: "Fred Jones",
                     groups: ["edit"] })
    assert_response :unprocessable_entity
    assert_match(/Month 13 is above the range 1-12/,
                 response.body.to_s,
                 "Missing or incorrect error message")
  end
end
