FactoryBot.define do
  factory :tree do
    lock_version { 1 }
    accepted_tree { true }
    description_html { "Sample Description html" }
    group_name { "Sample Group name" }
    host_name { "Sample Host name" }
    name { "Sample Name" }
    rdf_id { "Sample Rdf" }
    is_schema { true }
    is_read_only { true }
    CONSTRAINT { "Default CONSTRAINT" }
  end
end
