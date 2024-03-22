

require "test_helper"

# Single model test.
class InvalidRegionQualifiersAreRejectedTest < ActiveSupport::TestCase

  def setup
    @dist_s = "WA (naturalisd), NT (native and naturalised)"
    @allowed_regions = DistRegion.all.order(:sort_order).collect(&:name)
    @expected_error = "Invalid entry 'WA (naturalisd)' in: #{@dist_s}"
  end

  test "Invalid region qualifiers are rejected" do
    dv = Loader::Name::DistributionValidator.new(@dist_s, @allowed_regions) 
    assert_not(dv.validate, "Should not validate")
    assert_equal(dv.error, @expected_error, "Error should be #{@expected_error}")
  end
end
