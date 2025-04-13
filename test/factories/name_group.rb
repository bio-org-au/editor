# == Schema Information
#
# Table name: name_group
#
#  id               :bigint           not null, primary key
#  description_html :text
#  lock_version     :bigint           default(0), not null
#  name             :string(50)
#  rdf_id           :string(50)
#
# Indexes
#
#  name_group_rdfid              (rdf_id)
#  uk_5185nbyw5hkxqyyqgylfn2o6d  (name) UNIQUE
#
FactoryBot.define do
  factory :name_group do
    sequence(:name) {|n| "Sample Name #{n}" }
    rdf_id { "Sample Rdf" }
  end
end
