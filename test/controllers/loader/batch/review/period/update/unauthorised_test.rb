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

# Single controller test.
class BatchReviewPeriodUpdateUnauthorisedTest < ActionController::TestCase
  tests ::Loader::Batch::Review::PeriodsController

  test "update batch review period unauthorised" do
    @request.headers["Accept"] = "application/javascript"
    target = loader_batch_batch_review_batch_review_period(:review_period_one)
    patch(:update,
          params: { id: target.id,
                    "loader_batch_review_period"=>
                       {"id"=>"52329126",
                        "batch_review_id"=>"51785034",
                        "name"=>"asdfas",
                        "start_date(3i)"=>target.start_date.day.to_s,
                        "start_date(2i)"=>target.start_date.month.to_s,
                        "start_date(1i)"=>target.start_date.year.to_s,
                        "end_date(3i)"=>"",
                        "end_date(2i)"=>"",
                        "end_date(1i)"=>""},
                   "commit"=>"Save"}, 
         session: { username: "fred",
                    user_full_name: "Fred Jones",
                    groups: ["edit"] })
    assert_response :forbidden
  end
end
