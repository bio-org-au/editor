FactoryBot.define do
  factory :ar_internal_metadatum do
    key { "Sample Key" }
    value { "Sample Value" }
    without { Time.current }
    without { Time.current }
  end
end
