# frozen_string_literal: true
#
# == Schema Information
#
# Table name: name_resource(Available resources to record.)
#
#  id(The key for a resource linked to a name.)                        :bigint           not null, primary key
#  api_at(The time the last jira or automated job updated this record) :timestamptz
#  api_name(The last jira or automated job to update this record)      :string(50)
#  created_by(Who created the record)                                  :string(50)       not null
#  lock_version(A standard attribute for record lock management.)      :bigint           default(0), not null
#  note(User notes associated with this linked resource.)              :text
#  updated_by(Who updated the record)                                  :string(50)       not null
#  value(The identifier for this specific resource.)                   :text
#  created_at(The timestamp the record was created.)                   :timestamptz      not null
#  updated_at(The timestamp the record was last updated.)              :timestamptz      not null
#  name_id                                                             :bigint           not null
#  resource_host_id(The id of the type of linked resource.)            :bigint           not null
#
# Foreign Keys
#
#  name_resource_name_id_fkey      (name_id => name.id)
#  name_resource_resource_host_fk  (resource_host_id => resource_host.id)
#
class NameResource < ApplicationRecord
  include UserTrackable

  self.table_name = "name_resource"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :name
  belongs_to :resource_host, class_name: "ResourceHost", foreign_key: "resource_host_id"
end
