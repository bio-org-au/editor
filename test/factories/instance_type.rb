FactoryBot.define do
  factory :instance_type do
    lock_version { 1 }
    citing { true }
    deprecated { true }
    doubtful { true }
    misapplied { true }
    sequence(:name) {|n| "Instance Type Name #{n}" }
    nomenclatural { true }
    primary_instance { true }
    pro_parte { true }
    protologue { true }
    relationship { true }
    secondary_instance { true }
    sort_order { 1 }
    standalone { true }
    synonym { true }
    taxonomic { true }
    unsourced { true }
    rdf_id { "Sample Rdf" }
    has_label { "Sample Has label" }
    of_label { "Sample Of label" }
    bidirectional { true }
    alignment { true }
  end
end
