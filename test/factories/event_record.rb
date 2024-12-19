FactoryBot.define do
  factory :event_record do
    version { 1 }
    created_by { "Sample Created by" }
    dealt_with { true }
    type { "Sample Type" }
    updated_by { "Sample Updated by" }
  end
end
