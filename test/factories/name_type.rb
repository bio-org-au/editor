# == Schema Information
#
# Table name: name_type
#
#  id               :bigint           not null, primary key
#  autonym          :boolean          default(FALSE), not null
#  connector        :string(1)
#  cultivar         :boolean          default(FALSE), not null
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  formula          :boolean          default(FALSE), not null
#  hybrid           :boolean          default(FALSE), not null
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  scientific       :boolean          default(FALSE), not null
#  sort_order       :integer          default(0), not null
#  vernacular       :boolean          default(FALSE), not null
#  name_category_id :bigint           not null
#  name_group_id    :bigint           not null
#  rdf_id           :string(50)
#
# Indexes
#
#  name_type_rdfid  (rdf_id)
#  nt_unique_name   (name_group_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_10d0jlulq2woht49j5ccpeehu  (name_category_id => name_category.id)
#  fk_5r3o78sgdbxsf525hmm3t44gv  (name_group_id => name_group.id)
#
FactoryBot.define do
  factory :name_type do
    lock_version { 1 }
    autonym { true }
    cultivar { true }
    formula { true }
    hybrid { false }
    #sequence(:name) {|n| "Sample Name #{n}" }
    name { "phrase name" }
    scientific { false }
    sort_order { 1 }
    rdf_id { "Sample Rdf" }
    deprecated { false }
    vernacular { true }

    association :name_group
    association :name_category
  end
end
