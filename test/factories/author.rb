# == Schema Information
#
# Table name: author
#
#  id               :bigint           not null, primary key
#  abbrev           :string(100)
#  created_by       :string(255)      not null
#  date_range       :string(50)
#  full_name        :string(255)
#  lock_version     :bigint           default(0), not null
#  name             :string(1000)
#  notes            :string(1000)
#  source_id_string :string(100)
#  source_system    :string(50)
#  updated_by       :string(255)      not null
#  uri              :text
#  valid_record     :boolean          default(FALSE), not null
#  created_at       :timestamptz      not null
#  updated_at       :timestamptz      not null
#  duplicate_of_id  :bigint
#  ipni_id          :string(50)
#  namespace_id     :bigint           not null
#  source_id        :bigint
#
# Indexes
#
#  auth_source_index             (namespace_id,source_id,source_system)
#  auth_source_string_index      (source_id_string)
#  auth_system_index             (source_system)
#  author_abbrev_index           (abbrev)
#  author_name_index             (name)
#  uk_9kovg6nyb11658j2tv2yv4bsi  (abbrev) UNIQUE
#  uk_rd7q78koyhufe1edfb2rgfrum  (uri) UNIQUE
#
# Foreign Keys
#
#  fk_6a4p11f1bt171w09oo06m0wag  (duplicate_of_id => author.id)
#  fk_p0ysrub11cm08xnhrbrfrvudh  (namespace_id => namespace.id)
#
FactoryBot.define do
  factory :author do
    lock_version { 1 }
    sequence(:abbrev) {|n| "Sample Abbrev #{n}" }
    created_by { "Sample Created by" }
    date_range { "Sample Date range" }
    full_name { "Sample Full name" }
    ipni_id { "Sample Ipni" }
    name { "Sample Name" }
    notes { "Sample Notes" }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    updated_by { "Sample Updated by" }
    valid_record { true }
    sequence(:uri) {|n| "Sample Uri #{n}" }

    association :namespace
  end
end
