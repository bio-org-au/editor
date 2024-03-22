

require "test_helper"

# Single model test.
class InvalidlyOrderedRegionsAreRejectedTest < ActiveSupport::TestCase

  def setup
    @dist_s = "WA (naturalised), SA, NT (native and naturalised)"
    @allowed_regions = DistRegion.all.order(:sort_order).collect(&:name)
    @expected_error = "Regions not ordered correctly in: #{@dist_s}"
  end

  test "Invalidly ordered regions are rejected" do
    dv = Loader::Name::DistributionValidator.new(@dist_s, @allowed_regions) 
    assert_not(dv.validate, "Should not validate")
    assert_equal(dv.error, @expected_error, "Error should be #{@expected_error}")
  end
end
