

require "test_helper"

# Single model test.
class ValidatorTest < ActiveSupport::TestCase
  test "Can create Validator" do
    allowed_regions = DistRegion.all.order(:sort_order).collect(&:name)
    dv = Loader::Name::DistributionValidator.new( "Qld (naturalised)", allowed_regions) 
    assert(dv.validate)
  end
end
