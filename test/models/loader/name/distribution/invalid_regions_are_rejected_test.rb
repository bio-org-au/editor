

require "test_helper"

# Single model test.
class InvalidRegionsAreRejectedTest < ActiveSupport::TestCase

  def setup
    @dist_s = "WA (naturalised), sA"
    @allowed_regions = DistRegion.all.order(:sort_order).collect(&:name)
    @expected_error = "string: '#{@dist_s}' contains unknown region 'sA'"
  end

  test "Invalid regions are rejected" do
    dv = Loader::Name::DistributionValidator.new(@dist_s, @allowed_regions) 
    assert_not(dv.validate, "Should not validate")
    assert_equal(dv.error, @expected_error, "Error should be #{@expected_error}")
  end
end
