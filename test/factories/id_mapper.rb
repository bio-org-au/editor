FactoryBot.define do
  factory :id_mapper do
    from_id { 1 }
    namespace_id { 1 }
    system { "Sample System" }
    to_id { 1 }
  end
end
