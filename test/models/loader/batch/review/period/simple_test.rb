


require "test_helper"

# Single model test.
class BatchReviewPeriodSimpleTest < ActiveSupport::TestCase

  def setup
  end

  test "Duplicate regions are rejected" do
    assert_equal(5, Loader::Batch::Review::Period.all.size)
    assert !loader_batch_batch_review_batch_review_period(:review_period_starts_today).blank?
    assert loader_batch_batch_review_batch_review_period(:review_period_starts_today).active?,
               'Period that starts today should be active'
    assert !names(:the_regnum).blank?
               'Past period should be inactive'
    assert_not loader_batch_batch_review_batch_review_period(:review_period_past_yesterday).active?,
               'Past period should be inactive'
    assert_not loader_batch_batch_review_batch_review_period(:review_period_future_tomorrow).active?,
               'Future period should be inactive'
  end
end
