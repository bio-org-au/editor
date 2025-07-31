


require "test_helper"

# Single model test.
class BatchReviewPeriodSimpleTest < ActiveSupport::TestCase

  def setup
  end

  test "Review period start and end detected test" do
    assert_not loader_batch_batch_review_batch_review_period(:review_period_past_yesterday).active?,
               'Past period should be inactive'
    assert_not loader_batch_batch_review_batch_review_period(:review_period_future_tomorrow).active?,
               'Future period should be inactive'
    assert loader_batch_batch_review_batch_review_period(:review_period_two_no_end_date).active?,
               'Review period with no end date should be active'
  end
end
