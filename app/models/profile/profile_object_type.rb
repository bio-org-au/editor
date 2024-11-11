# app/models/profile/profile_object_type.rb
# == Schema Information
#
# Table name: profile_object_type(The supported object types within the National Species List infrastructure i.e text, reference, (later distribution etc))
#
#  id(A system wide unique identifier allocated to each profile object type.)            :bigint           not null, primary key
#  api_date(The date when a script, jira or services task last changed this record.)     :timestamptz
#  api_name(The name of a script, jira or services task which last changed this record.) :string(50)
#  created_by(The user id of the person who created this data)                           :string(50)       not null
#  internal_notes(Team notes about the management or maintenance of this object type.)   :text
#  is_deprecated(Object type no longer available for use.)                               :boolean          default(FALSE)
#  lock_version(Internal Postgres management for record locking.)                        :bigint           default(0)
#  name(The name of the table which contains this data type.)                            :text             not null
#  updated_by(The user id of the person who last updated this data)                      :string(50)       not null
#  created_at(The date and time this data was created.)                                  :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                  :timestamptz      not null
#  rdf_id(Alternate unique key with english (like) value i.e. text.)                     :text             not null
#
# Indexes
#
#  profile_object_type_rdf_id_key  (rdf_id) UNIQUE
#
module Profile
  class ProfileObjectType < ApplicationRecord
    self.table_name = "profile_object_type"
    
    has_many :profile_items, class_name: 'Profile::ProfileItem', primary_key: 'rdf_id', foreign_key: 'profile_object_rdf_id'

    validates :name, presence: true
  end
end
