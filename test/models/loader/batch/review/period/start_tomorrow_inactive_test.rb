


require "test_helper"

# Single model test.
class BatchReviewPeriodStartTomorrowInactiveTest < ActiveSupport::TestCase

  test "Period should be inactive if starts tomorrow test" do
    assert_not loader_batch_batch_review_batch_review_period(:review_period_future_tomorrow).active?,
               'Period starting tomorrow should be inactive'
  end
end
