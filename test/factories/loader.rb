FactoryBot.define do
  factory :loader do
    name { "Sample Name" }
    for_reviewer { true }
    for_compiler { true }
    deprecated { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
  end
end
