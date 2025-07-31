# == Schema Information
#
# Table name: product_item_config(The profile item type(s) available for a specific Product and the customisation for that product.)
#
#  id(A system wide unique identifier allocated to each profile item config record.)                                     :bigint           not null, primary key
#  api_date(The date when a system user, script, jira or services task last changed this record.)                        :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.)                    :string(50)
#  created_by(The user id of the person who created this data)                                                           :string(50)       not null
#  display_html                                                                                                          :text
#  external_context(Export profile content to this external source.)                                                     :text
#  external_mapping(Export profile content to this external source mapping.)                                             :text
#  internal_notes(Team notes about the management or maintenance of this item type.)                                     :text
#  is_deprecated(Profile item type no longer available for editing in this product.)                                     :boolean          default(FALSE), not null
#  is_hidden(Profile item type hidden from public output.)                                                               :boolean          default(FALSE), not null
#  lock_version                                                                                                          :integer          default(0), not null
#  sort_order(The order of the profile item in a product. Determines the order presented to the user within the editor.) :decimal(5, 2)
#  tool_tip(The helper text associated with this profile item type in a profile product.)                                :text
#  updated_by(The user id of the person who last updated this data)                                                      :string(50)       not null
#  created_at(The date and time this data was created.)                                                                  :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                                                  :timestamptz      not null
#  product_id(The product that uses this profile item type.)                                                             :bigint           not null
#  profile_item_type_id(A profile item type used by this product.)                                                       :bigint           not null
#
# Indexes
#
#  product_item_config_product_id_profile_item_type_id_key  (product_id,profile_item_type_id) UNIQUE
#  product_item_config_product_id_sort_order_key            (product_id,sort_order) UNIQUE
#  product_item_config_product_item_u                       (product_id,profile_item_type_id) UNIQUE
#
# Foreign Keys
#
#  product_item_config_product_id_fkey            (product_id => product.id)
#  product_item_config_profile_item_type_id_fkey  (profile_item_type_id => profile_item_type.id)
#
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
