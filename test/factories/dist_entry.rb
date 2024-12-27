FactoryBot.define do
  factory :dist_entry do
    lock_version { 1 }
    display { "Sample Display" }
    region_id { 1 }
    sort_order { 1 }
  end
end
