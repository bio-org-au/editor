

require "test_helper"

# Single model test.
class EmptyDistributionIsAllowedTest < ActiveSupport::TestCase

  def setup
    @dist_s = nil
    @allowed_regions = DistRegion.all.order(:sort_order).collect(&:name)
  end

  test "Empty distribution is allowed" do
    dv = Loader::Name::DistributionValidator.new(@dist_s, @allowed_regions) 
    assert(dv.validate, "Should validate")
    assert_nil(dv.error, "Should be no error")
  end
end
