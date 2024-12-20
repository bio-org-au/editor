FactoryBot.define do
  factory :reference do
    lock_version { 1 }
    abbrev_title { "Sample Abbrev title" }
    bhl_url { "Sample Bhl url" }
    citation { "Sample Citation" }
    citation_html { "Sample Citation html" }
    created_by { "Sample Created by" }
    display_title { "Sample Display title" }
    sequence(:doi) {|n| "Sample Doi #{n}" }
    edition { "Sample Edition" }
    isbn { "Sample Isbn" }
    issn { "Sample Issn" }
    notes { "Sample Notes" }
    pages { "Sample Pages" }
    published { true }
    published_location { "Sample Published location" }
    publisher { "Sample Publisher" }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    title { "Sample Title" }
    tl2 { "Sample Tl2" }
    updated_by { "Sample Updated by" }
    valid_record { true }
    verbatim_author { "Sample Verbatim author" }
    verbatim_citation { "Sample Verbatim citation" }
    verbatim_reference { "Sample Verbatim reference" }
    volume { "Sample Volume" }
    sequence(:uri) {|n| "Sample uri #{n}" }

    association :ref_type
    association :ref_author_role
    association :language
    association :author
    association :namespace
    
  end
end
