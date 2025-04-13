# == Schema Information
#
# Table name: ref_type
#
#  id                 :bigint           not null, primary key
#  description_html   :text
#  lock_version       :bigint           default(0), not null
#  name               :string(50)       not null
#  parent_optional    :boolean          default(FALSE), not null
#  use_parent_details :boolean          default(FALSE), not null
#  parent_id          :bigint
#  rdf_id             :string(50)
#
# Indexes
#
#  ref_type_rdfid                (rdf_id)
#  uk_4fp66uflo7rgx59167ajs0ujv  (name) UNIQUE
#
# Foreign Keys
#
#  fk_51alfoe7eobwh60yfx45y22ay  (parent_id => ref_type.id)
#
FactoryBot.define do
  factory :ref_type do
    lock_version { 1 }
    sequence(:name) {|n| "Sample Name #{n}" }
    parent_optional { true }
    rdf_id { "Sample Rdf" }
    use_parent_details { true }
  end
end
