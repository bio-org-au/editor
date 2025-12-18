# frozen_string_literal: true
#
# == Schema Information
#
# Table name: resource_host(An available resource.)
#
#  id(The key for a resource_host.)                                                                     :bigint           not null, primary key
#  created_by(Who created the record)                                                                   :string(50)       not null
#  deprecated(A flag to indicate this resource is no longer used.)                                      :boolean          default(FALSE), not null
#  description(A description of the resource.)                                                          :text
#  for_instance(A boolean that indicates this resource can be linked to an taxon name usage (instance)) :boolean          default(FALSE)
#  for_name(A boolean that indicates this resource can be linked to a name)                             :boolean          default(FALSE)
#  for_reference(A boolean that indicates this resource can be linked to a reference)                   :boolean          default(FALSE)
#  lock_version(A standard attribute for record lock management.)                                       :bigint           default(0), not null
#  name(A short name for a resource.)                                                                   :string(50)
#  resolving_url(The stem URL associated with this resource.)                                           :text             not null
#  sort_order(The order resources are presented to editors and on output.)                              :integer          default(0), not null
#  updated_by(Who updated the record)                                                                   :string(50)       not null
#  created_at(The timestamp the record was created.)                                                    :timestamptz      not null
#  updated_at(The timestamp the record was last updated.)                                               :timestamptz      not null
#  rdf_id(A unique identifier for a resource across all resource_host records in the NSL)               :string(50)       not null
#
# Indexes
#
#  lr_unique_name  (name) UNIQUE
#
class ResourceHost < ApplicationRecord
  include UserTrackable

  self.table_name = "resource_host"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  has_many :name_resources, dependent: :restrict_with_error

  validates :resolving_url, presence: true
  validates :rdf_id, presence: true

  scope :for_names, -> { where(for_name: true) }
end
