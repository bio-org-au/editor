# app/models/profile/profile_item_annotation.rb
# == Schema Information
#
# Table name: profile_item_annotation(An annotation made on a profile item.)
#
#  id(A system wide unique identifier allocated to each profile annotation record.)                   :bigint           not null, primary key
#  api_date(The date when a system user, script, jira or services task last changed this record.)     :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.) :string(50)
#  created_by(The user id of the person who created this data)                                        :string(50)       not null
#  lock_version(A system field to manage row level locking.)                                          :integer          default(0), not null
#  source_id_string(The identifier from the source system that this profile text was imported from.)  :string(100)
#  source_system(The source system that this profile text was imported from.)                         :text
#  updated_by(The user id of the person who last updated this data)                                   :string(50)       not null
#  value(The annotation statement.)                                                                   :text             not null
#  created_at(The date and time this data was created.)                                               :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                               :timestamptz      not null
#  profile_item_id(The profile item about which this annotation is made.)                             :bigint           not null
#  source_id(The key at the source system imported on migration)                                      :bigint
#
# Indexes
#
#  profile_item_annotation_item_i  (profile_item_id)
#
# Foreign Keys
#
#  profile_item_annotation_profile_item_id_fkey  (profile_item_id => profile_item.id)
#
module Profile
    class ProfileItemAnnotation < ApplicationRecord
      include UserTrackable

      self.table_name = "profile_item_annotation"
      self.primary_key = "id"

      belongs_to :profile_item, class_name: 'Profile::ProfileItem', foreign_key: 'profile_item_id'
      has_one :product_item_config, through: :profile_item

      validates :value, presence: true
      validates :profile_item_id, uniqueness: { message: "Profile item annotation must be unique per profile item" }
    end
  end

