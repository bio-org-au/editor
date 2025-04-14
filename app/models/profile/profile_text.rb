# app/models/profile/profile_text.rb
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
module Profile
  class ProfileText < ApplicationRecord
    strip_attributes
    self.table_name = "profile_text"
    self.primary_key = "id"

    has_one :profile_item, class_name: "Profile::ProfileItem", foreign_key: "profile_text_id"
    has_one :product_item_config, through: :profile_item

    validates :value_md, presence: true
    validates :value, presence: true
  end
end
