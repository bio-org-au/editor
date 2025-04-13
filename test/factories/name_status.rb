# == Schema Information
#
# Table name: name_status
#
#  id               :bigint           not null, primary key
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  display          :boolean          default(TRUE), not null
#  lock_version     :bigint           default(0), not null
#  name             :string(50)
#  nom_illeg        :boolean          default(FALSE), not null
#  nom_inval        :boolean          default(FALSE), not null
#  name_group_id    :bigint           not null
#  name_status_id   :bigint
#  rdf_id           :string(50)
#
# Indexes
#
#  name_status_rdfid  (rdf_id)
#  ns_unique_name     (name_group_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_g4o6xditli5a0xrm6eqc6h9gw  (name_status_id => name_status.id)
#  fk_swotu3c2gy1hp8f6ekvuo7s26  (name_group_id => name_group.id)
#
FactoryBot.define do
  factory :name_status do
    display { true }
    name { "Sample Name" }
    nom_illeg { true }
    nom_inval { true }
    rdf_id { "Sample Rdf" }
    deprecated { true }

    association :name_group
  end
end
