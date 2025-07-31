


require "test_helper"

# Single model test.
class BatchReviewPeriodEndYesterdayInactiveTest < ActiveSupport::TestCase

  test "Past period should be inactive if ends yesterday test" do
    assert_not loader_batch_batch_review_batch_review_period(:review_period_past_yesterday).active?,
               'Past period should be inactive'
  end
end
