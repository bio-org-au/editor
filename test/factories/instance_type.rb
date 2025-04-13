# == Schema Information
#
# Table name: instance_type
#
#  id                 :bigint           not null, primary key
#  alignment          :boolean          default(FALSE), not null
#  bidirectional      :boolean          default(FALSE), not null
#  citing             :boolean          default(FALSE), not null
#  deprecated         :boolean          default(FALSE), not null
#  description_html   :text
#  doubtful           :boolean          default(FALSE), not null
#  has_label          :string(255)      default("not set"), not null
#  lock_version       :bigint           default(0), not null
#  misapplied         :boolean          default(FALSE), not null
#  name               :string(255)      not null
#  nomenclatural      :boolean          default(FALSE), not null
#  of_label           :string(255)      default("not set"), not null
#  primary_instance   :boolean          default(FALSE), not null
#  pro_parte          :boolean          default(FALSE), not null
#  protologue         :boolean          default(FALSE), not null
#  relationship       :boolean          default(FALSE), not null
#  secondary_instance :boolean          default(FALSE), not null
#  sort_order         :integer          default(0), not null
#  standalone         :boolean          default(FALSE), not null
#  synonym            :boolean          default(FALSE), not null
#  taxonomic          :boolean          default(FALSE), not null
#  unsourced          :boolean          default(FALSE), not null
#  rdf_id             :string(50)
#
# Indexes
#
#  instance_type_rdfid           (rdf_id)
#  uk_j5337m9qdlirvd49v4h11t1lk  (name) UNIQUE
#
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
