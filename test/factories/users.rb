FactoryBot.define do
  factory :user do
    sequence(:username) {|n| "user#{n}"}
    full_name { "Tester" }
    groups { ["login"] }

    trait :admin do
      groups { ["admin"] }
    end
  end
end
