# == Schema Information
#
# Table name: shard_config
#
#  id         :bigint           not null, primary key
#  deprecated :boolean          default(FALSE), not null
#  name       :string(255)      not null
#  use_notes  :string(255)
#  value      :string(5000)     not null
#
FactoryBot.define do
  factory :shard_config do
    name { "Sample Name" }
    value { "Sample Value" }
    deprecated { true }
    use_notes { "Sample Use notes" }
  end
end
