FactoryBot.define do
  factory :product_item_config, class: "Profile::ProductItemConfig" do
    is_deprecated { true }
    is_hidden { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    api_date { Time.current }
    display_html { "Etymology"}

    association :profile_item_type
    association :product
  end
end
