

require "test_helper"

# Single model test.
class ExtraQualifiersAreRejectedTest < ActiveSupport::TestCase

  def setup
    @dist_s = "WA (naturalised), NT (native) (naturalised), SA (native and naturalised)"
    @allowed_regions = DistRegion.all.order(:sort_order).collect(&:name)
    @expected_error = "Invalid entry 'NT (native) (naturalised)' in: #{@dist_s}"
  end

  test "Extra qualifiers are rejected" do
    dv = Loader::Name::DistributionValidator.new(@dist_s, @allowed_regions) 
    assert_not(dv.validate, "Should not validate")
    assert_equal(dv.error, @expected_error, "Error should be #{@expected_error}")
  end
end
