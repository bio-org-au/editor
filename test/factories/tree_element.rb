FactoryBot.define do
  factory :tree_element do
    lock_version { 1 }
    display_html { "Sample Display html" }
    excluded { true }
    instance_id { 1 }
    instance_link { "Sample Instance link" }
    name_element { "Sample Name element" }
    name_id { 1 }
    name_link { "Sample Name link" }
    rank { "Sample Rank" }
    simple_name { "Sample Simple name" }
    source_shard { "Sample Source shard" }
    synonyms_html { "Sample Synonyms html" }
    updated_by { "Sample Updated by" }
  end
end
