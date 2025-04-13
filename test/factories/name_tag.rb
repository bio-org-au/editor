# == Schema Information
#
# Table name: name_tag
#
#  id           :bigint           not null, primary key
#  lock_version :bigint           default(0), not null
#  name         :string(255)      not null
#
# Indexes
#
#  uk_o4su6hi7vh0yqs4c1dw0fsf1e  (name) UNIQUE
#
FactoryBot.define do
  factory :name_tag do
    name { "Sample Name" }
    lock_version { 1 }
  end
end
