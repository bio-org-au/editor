# == Schema Information
#
# Table name: org
#
#  id           :bigint           not null, primary key
#  abbrev       :string(30)       not null
#  created_by   :string(50)       not null
#  deprecated   :boolean          default(FALSE), not null
#  lock_version :bigint           default(0), not null
#  name         :string(100)      not null
#  no_org       :boolean          default(FALSE), not null
#  updated_by   :string(50)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#
# Indexes
#
#  org_abbrev_key  (abbrev) UNIQUE
#  org_name_key    (name) UNIQUE
#
FactoryBot.define do
  factory :org do
    name { "Sample Name" }
    abbrev { "Sample Abbrev" }
    deprecated { true }
    not_a_real_org { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    can_vote { true }
  end
end
