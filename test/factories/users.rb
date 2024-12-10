FactoryBot.define do
  factory :user do
    sequence(:username) {|n| "user#{n}"}
    full_name { "Tester" }
  end

  trait :foa do
    groups { ['foa'] }
  end

  trait :edit do
    groups { ['edit'] }
  end

  trait :admin do
    groups { ['admin'] }
  end

  trait :apc do
    groups { ['APC'] }
  end

  trait :qa do
    groups { ['QA'] }
  end

  trait :treebuilder do
    groups { ['treebuilder'] }
  end

  trait :reviewer do
    groups { ['taxonomic-review'] }
  end

  trait :compiler do
    groups { ['treebuilder'] }
  end

  trait :batch_loader do
    groups { ['batch-loader'] }
  end

  trait :loader_2_tab_loader do
    groups { ['loader-2-tab"'] }
  end

  trait :profile_v2_context do
    groups { ['foa-context-group'] }
  end
end
