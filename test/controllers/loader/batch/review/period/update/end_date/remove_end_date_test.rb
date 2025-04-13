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
class BatchReviewPeriodUpdateEndDateRemoveTest < ActionController::TestCase
  tests ::Loader::Batch::Review::PeriodsController

  test "update batch review period end date remove" do
    @request.headers["Accept"] = "application/javascript"
    batch_review_period = loader_batch_batch_review_batch_review_period(:review_period_one)
    assert batch_review_period.end_date.present?
    patch(:update,
          params: { id: batch_review_period.id,
                    "loader_batch_review_period"=>{"id"=>batch_review_period.id,
                                                   "batch_review_id"=>batch_review_period.batch_review.id,
                                                   "name"=>"Review Period One",
                                                   "start_date(3i)"=>Date.today.day.to_s,
                                                   "start_date(2i)"=>Date.today.month.to_s,
                                                   "start_date(1i)"=>Date.today.year.to_s,
                                                   "end_date(3i)"=>'',
                                                   "end_date(2i)"=>'',
                                                   "end_date(1i)"=>''
                    },
                   "commit"=>"Save"}, 
         session: { username: "fred",
                    user_full_name: "Fred Jones",
                    groups: ["batch-loader"] })
    assert_response :success
    updated = Loader::Batch::Review::Period.find(batch_review_period.id)
    assert updated.end_date.blank?, 'Updated end date should be blank'
  end
end
