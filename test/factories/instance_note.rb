# == Schema Information
#
# Table name: instance_note
#
#  id                   :bigint           not null, primary key
#  created_by           :string(50)       not null
#  lock_version         :bigint           default(0), not null
#  source_id_string     :string(100)
#  source_system        :string(50)
#  updated_by           :string(50)       not null
#  value                :string(4000)     not null
#  created_at           :timestamptz      not null
#  updated_at           :timestamptz      not null
#  instance_id          :bigint           not null
#  instance_note_key_id :bigint           not null
#  namespace_id         :bigint           not null
#  source_id            :bigint
#
# Indexes
#
#  note_instance_index       (instance_id)
#  note_key_index            (instance_note_key_id)
#  note_source_index         (namespace_id,source_id,source_system)
#  note_source_string_index  (source_id_string)
#  note_system_index         (source_system)
#
# Foreign Keys
#
#  fk_bw41122jb5rcu8wfnog812s97  (instance_id => instance.id)
#  fk_f6s94njexmutjxjv8t5dy1ugt  (namespace_id => namespace.id)
#  fk_he1t3ug0o7ollnk2jbqaouooa  (instance_note_key_id => instance_note_key.id)
#
FactoryBot.define do
  factory :instance_note do
    lock_version { 1 }
    created_by { "Sample Created by" }
    instance_id { 1 }
    instance_note_key_id { 1 }
    namespace_id { 1 }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    updated_by { "Sample Updated by" }
    value { "Sample Value" }
  end
end
