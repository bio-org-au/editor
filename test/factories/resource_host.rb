# frozen_string_literal: true

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
FactoryBot.define do
  factory :resource_host do
    sequence(:name) { |n| "Resource Host #{n}" }
    description { "Sample Resource Host Description" }
    resolving_url { "https://example.com/resource" }
    sequence(:rdf_id) { |n| "resource_host_#{n}" }
    for_name { true }
    for_reference { false }
    for_instance { false }
    deprecated { false }
    sort_order { 0 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
  end
end
