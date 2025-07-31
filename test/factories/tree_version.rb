# == Schema Information
#
# Table name: tree_version
#
#  id                  :bigint           not null, primary key
#  created_by          :string(255)      not null
#  draft_name          :text             not null
#  lock_version        :bigint           default(0), not null
#  log_entry           :text
#  published           :boolean          default(FALSE), not null
#  published_at        :timestamptz
#  published_by        :string(100)
#  created_at          :timestamptz      not null
#  previous_version_id :bigint
#  tree_id             :bigint           not null
#
# Foreign Keys
#
#  fk_4q3huja5dv8t9xyvt5rg83a35  (tree_id => tree.id)
#  fk_tiniptsqbb5fgygt1idm1isfy  (previous_version_id => tree_version.id)
#
FactoryBot.define do
  factory :tree_version do
    lock_version { 1 }
    created_by { "Sample Created by" }
    draft_name { "Sample Draft name" }
    published { true }
    published_by { "Sample Published by" }
    tree_id { 1 }

    association :tree
  end
end
