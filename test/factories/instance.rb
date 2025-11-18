# == Schema Information
#
# Table name: instance
#
#  id                   :bigint           not null, primary key
#  bhl_url              :string(4000)
#  cached_synonymy_html :text
#  created_by           :string(50)       not null
#  draft                :boolean          default(FALSE), not null
#  lock_version         :bigint           default(0), not null
#  nomenclatural_status :string(50)
#  page                 :string(255)
#  page_qualifier       :string(255)
#  source_id_string     :string(100)
#  source_system        :string(50)
#  uncited              :boolean          default(FALSE), not null
#  updated_by           :string(1000)     not null
#  uri                  :text
#  valid_record         :boolean          default(FALSE), not null
#  verbatim_name_string :string(255)
#  created_at           :timestamptz      not null
#  updated_at           :timestamptz      not null
#  cited_by_id          :bigint
#  cites_id             :bigint
#  instance_type_id     :bigint           not null
#  name_id              :bigint           not null
#  namespace_id         :bigint           not null
#  parent_id            :bigint
#  reference_id         :bigint           not null
#  source_id            :bigint
#
# Indexes
#
#  instance_citedby_index        (cited_by_id)
#  instance_cites_index          (cites_id)
#  instance_instancetype_index   (instance_type_id)
#  instance_name_index           (name_id)
#  instance_parent_index         (parent_id)
#  instance_reference_index      (reference_id)
#  instance_source_index         (namespace_id,source_id,source_system)
#  instance_source_string_index  (source_id_string)
#  instance_system_index         (source_system)
#  no_duplicate_synonyms         (name_id,reference_id,instance_type_id,page,cites_id,cited_by_id) UNIQUE
#  uk_bl9pesvdo9b3mp2qdna1koqc7  (uri) UNIQUE
#
# Foreign Keys
#
#  fk_30enb6qoexhuk479t75apeuu5  (cites_id => instance.id)
#  fk_gdunt8xo68ct1vfec9c6x5889  (name_id => name.id)
#  fk_gtkjmbvk6uk34fbfpy910e7t6  (namespace_id => namespace.id)
#  fk_hb0xb97midopfgrm2k5fpe3p1  (parent_id => instance.id)
#  fk_lumlr5avj305pmc4hkjwaqk45  (reference_id => reference.id)
#  fk_o80rrtl8xwy4l3kqrt9qv0mnt  (instance_type_id => instance_type.id)
#  fk_pr2f6peqhnx9rjiwkr5jgc5be  (cited_by_id => instance.id)
#
FactoryBot.define do
  factory :instance do
    lock_version { 1 }
    bhl_url { "Sample Bhl url" }
    created_by { "Sample Created by" }
    draft { true }
    nomenclatural_status { "Sample Nomenclatural status" }
    page { "Sample Page" }
    page_qualifier { "Sample Page qualifier" }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    updated_by { "Sample Updated by" }
    valid_record { true }
    verbatim_name_string { "Sample Verbatim name string" }
    uncited { true }

    association :namespace
    association :name
    association :reference
    association :instance_type

    trait :synonym_instance do
      uncited { false }
      valid_record { false }
      after(:create) do |instance|
        instance_type = create(:instance_type, primary_instance: false)
        instance.instance_type_id = instance_type.id
      end
    end
  end
end
