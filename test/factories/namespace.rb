# == Schema Information
#
# Table name: namespace
#
#  id               :bigint           not null, primary key
#  description_html :text
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  rdf_id           :string(50)
#
# Indexes
#
#  namespace_rdfid               (rdf_id)
#  uk_eq2y9mghytirkcofquanv5frf  (name) UNIQUE
#
FactoryBot.define do
  factory :namespace do
    sequence(:name) {|n| "Sample Name #{n}" }
    rdf_id { "Sample Rdf" }
  end
end
