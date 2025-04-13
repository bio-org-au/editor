# == Schema Information
#
# Table name: dist_entry
#
#  id           :bigint           not null, primary key
#  display      :string(255)      not null
#  lock_version :bigint           default(0), not null
#  sort_order   :integer          default(0), not null
#  region_id    :bigint           not null
#
# Foreign Keys
#
#  fk_ffleu7615efcrsst8l64wvomw  (region_id => dist_region.id)
#
FactoryBot.define do
  factory :dist_entry do
    lock_version { 1 }
    display { "Sample Display" }
    region_id { 1 }
    sort_order { 1 }
  end
end
