FactoryBot.define do
  factory :notification do
    version { 1 }
    message { "Sample Message" }
    object_id { 1 }
  end
end
