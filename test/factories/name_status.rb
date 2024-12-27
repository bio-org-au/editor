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
