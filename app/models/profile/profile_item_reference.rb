# app/models/profile/profile_reference.rb
# == Schema Information
#
# Table name: profile_item_reference(The use of a reference for a profile i.e. list of general references for the taxon being described by this profile.)
#
#  annotation(An annotation made by the profile editor about the use of this reference.)              :text
#  api_date(The date when a system user, script, jira or services task last changed this record.)     :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.) :string(50)
#  created_by(The user id of the person who created this data)                                        :string(50)       not null
#  lock_version(A system field to manage row level locking.)                                          :integer          default(0), not null
#  pages(The page number(s) for this usage of the reference.)                                         :text
#  updated_by(The user id of the person who last updated this data)                                   :string(50)       not null
#  created_at(The date and time this data was created.)                                               :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                               :timestamptz      not null
#  profile_item_id(The profile item which is using this reference.)                                   :bigint           not null, primary key
#  reference_id(The reference which is being used by this profile item.)                              :bigint           not null, primary key
#
# Foreign Keys
#
#  profile_item_reference_profile_item_id_fkey  (profile_item_id => profile_item.id)
#  profile_item_reference_reference_id_fkey     (reference_id => reference.id)
#
module Profile
    class ProfileItemReference < ApplicationRecord
      self.table_name = "profile_item_reference"

      belongs_to :profile_item, class_name: 'Profile::ProfileItem', foreign_key: 'profile_item_id'
      belongs_to :reference, class_name: 'Reference', foreign_key: 'reference_id'

      validate :reference_and_profile_item_uniqueness, on: :create

      def profile_item_id_reference_id
        [profile_item_id, reference_id].join('_')
      end

      private

      def reference_and_profile_item_uniqueness
        errors.add(:base, "Only one reference per profile item is permitted") if Profile::ProfileItemReference.exists?(profile_item_id: self.profile_item_id, reference_id: self.reference_id)
      end
    end
  end

