# == Schema Information
#
# Table name: ref_author_role
#
#  id               :bigint           not null, primary key
#  description_html :text
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  rdf_id           :string(50)
#
# Indexes
#
#  ref_author_role_rdfid         (rdf_id)
#  uk_l95kedbafybjpp3h53x8o9fke  (name) UNIQUE
#
FactoryBot.define do
  factory :ref_author_role do
    lock_version { 1 }
    sequence(:name) {|n| "Sample Name #{n}" }
    rdf_id { "Sample Rdf" }
  end
end
