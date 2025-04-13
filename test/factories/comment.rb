# == Schema Information
#
# Table name: comment
#
#  id           :bigint           not null, primary key
#  created_by   :string(50)       not null
#  lock_version :bigint           default(0), not null
#  text         :text             not null
#  updated_by   :string(50)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#  author_id    :bigint
#  instance_id  :bigint
#  name_id      :bigint
#  reference_id :bigint
#
# Indexes
#
#  comment_author_index     (author_id)
#  comment_instance_index   (instance_id)
#  comment_name_index       (name_id)
#  comment_reference_index  (reference_id)
#
# Foreign Keys
#
#  fk_3tfkdcmf6rg6hcyiu8t05er7x  (reference_id => reference.id)
#  fk_6oqj6vquqc33cyawn853hfu5g  (instance_id => instance.id)
#  fk_9aq5p2jgf17y6b38x5ayd90oc  (author_id => author.id)
#  fk_h9t5eaaqhnqwrc92rhryyvdcf  (name_id => name.id)
#
FactoryBot.define do
  factory :comment do
    lock_version { 1 }
    created_by { "Sample Created by" }
    text { "Sample Text" }
    updated_by { "Sample Updated by" }
  end
end
