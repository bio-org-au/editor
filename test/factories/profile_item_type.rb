# == Schema Information
#
# Table name: profile_item_type(The superset of terms for Products arranged hierarchically and the object type associated with this term.)
#
#  id(A system wide unique identifier allocated to each profile item type.)                           :bigint           not null, primary key
#  api_date(The date when a system user, script, jira or services task last changed this record.)     :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.) :string(50)
#  created_by(The user id of the person who created this data)                                        :string(50)       not null
#  description_html(The global definition of this term.)                                              :text
#  internal_notes(Team notes about the management or maintenance of this item type.)                  :text
#  is_deprecated(Object type no longer available for use.)                                            :boolean          default(FALSE)
#  lock_version(Internal Postgres management for record locking.)                                     :integer          default(0), not null
#  name(The full path to this profile item type as a Postgres btree.)                                 :text             not null
#  sort_order(The default sort order for the superset of terms.)                                      :decimal(5, 2)    not null
#  updated_by(The user id of the person who last updated this data)                                   :string(50)       not null
#  created_at(The date and time this data was created.)                                               :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                               :timestamptz      not null
#  profile_object_type_id(The object type for this profile item type.)                                :bigint           not null
#  rdf_id(Alternate unique key with an english (like) value i.e. morphology.)                         :text             not null
#
# Indexes
#
#  pit_path_u                    (name) UNIQUE
#  profile_item_type_rdf_id_key  (rdf_id) UNIQUE
#
# Foreign Keys
#
#  profile_item_type_profile_object_type_id_fkey  (profile_object_type_id => profile_object_type.id)
#
FactoryBot.define do
  factory :profile_item_type, class: "Profile::ProfileItemType" do
    profile_object_type_id { 1 }
    name { "Sample Name" }
    rdf_id { "Sample Rdf" }
    is_deprecated { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    api_date { Time.current }
    sequence(:sort_order) {|n| n}

    association :profile_object_type
  end
end
