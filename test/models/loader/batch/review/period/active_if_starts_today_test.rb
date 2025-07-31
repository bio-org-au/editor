


require "test_helper"

# Single model test.
class BatchReviewPeriodActiveStartsTodayTest < ActiveSupport::TestCase

  test "Period active if starts today test" do
    assert loader_batch_batch_review_batch_review_period(:review_period_starts_today).active?,
               'Period that starts today should be active'
  end
end
