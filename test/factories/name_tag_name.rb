# == Schema Information
#
# Table name: name_tag_name
#
#  created_by :string(255)      not null
#  updated_by :string(255)      not null
#  created_at :timestamptz      not null
#  updated_at :timestamptz      not null
#  name_id    :bigint           not null, primary key
#  tag_id     :bigint           not null, primary key
#
# Indexes
#
#  name_tag_name_index  (name_id)
#  name_tag_tag_index   (tag_id)
#
# Foreign Keys
#
#  fk_22wdc2pxaskytkgpdgpyok07n  (name_id => name.id)
#  fk_2uiijd73snf6lh5s6a82yjfin  (tag_id => name_tag.id)
#
FactoryBot.define do
  factory :name_tag_name do
    name_id { 1 }
    tag_id { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
  end
end
