# == Schema Information
#
# Table name: profile_text(Text based content for a taxon concept about a profile item type. It has one original source (fact) and can be quoted (or linked to) many times.)
#
#  id(A system wide unique identifier allocated to each profile text record.)                         :bigint           not null, primary key
#  api_date(The date when a system user, script, jira or services task last changed this record.)     :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.) :string(50)
#  created_by(The user id of the person who created this data)                                        :string(50)       not null
#  lock_version(A system field to manage row level locking.)                                          :integer          default(0), not null
#  source_id_string(The identifier from the source system that this profile text was imported from.)  :string(100)
#  source_system(The source system that this profile text was imported from.)                         :string(50)
#  updated_by(The user id of the person who last updated this data)                                   :string(50)       not null
#  value(The original text written for a defined category of information, for a taxon in a profile.)  :text             not null
#  value_md(The mark down version of the text.)                                                       :text
#  created_at(The date and time this data was created.)                                               :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                               :timestamptz      not null
#  source_id(The key at the source system imported on migration)                                      :bigint
#
# Indexes
#
#  profile_text_value_md_i  (value) USING gin
#
FactoryBot.define do
  factory :profile_text, class: "Profile::ProfileText" do
    value { "Sample Value" }
    source_system { "Sample Source system" }
    source_id_string { "Sample Source id string" }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    value_md { "Sample Value Md"}
    api_date { Time.current }
  end
end
