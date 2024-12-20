FactoryBot.define do
  factory :shard_config do
    name { "Sample Name" }
    value { "Sample Value" }
    deprecated { true }
    use_notes { "Sample Use notes" }
  end
end
