# == Schema Information
#
# Table name: db_version
#
#  id      :bigint           not null, primary key
#  version :integer          not null
#
FactoryBot.define do
  factory :db_version do
    version { 1 }
  end
end
