# == Schema Information
#
# Table name: instance_note_key
#
#  id               :bigint           not null, primary key
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  sort_order       :integer          default(0), not null
#  rdf_id           :string(50)
#
# Indexes
#
#  instance_note_key_rdfid       (rdf_id)
#  uk_a0justk7c77bb64o6u1riyrlh  (name) UNIQUE
#
FactoryBot.define do
  factory :instance_note_key do
    lock_version { 1 }
    deprecated { true }
    name { "Sample Name" }
    sort_order { 1 }
    rdf_id { "Sample Rdf" }
  end
end
