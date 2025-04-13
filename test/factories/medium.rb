FactoryBot.define do
  factory :medium do
    version { 1 }
    data { "Default data" }
    description { "Sample Description" }
    file_name { "Sample File name" }
    mime_type { "Sample Mime type" }
  end
end
