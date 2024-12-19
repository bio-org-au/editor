FactoryBot.define do
  factory :dist_status do
    lock_version { 1 }
    deprecated { true }
    def_link { "Sample Def link" }
    name { "Sample Name" }
    sort_order { 1 }
  end
end
