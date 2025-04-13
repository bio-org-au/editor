# == Schema Information
#
# Table name: dist_region
#
#  id               :bigint           not null, primary key
#  def_link         :string(255)
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  sort_order       :integer          default(0), not null
#
FactoryBot.define do
  factory :dist_region do
    lock_version { 1 }
    deprecated { true }
    def_link { "Sample Def link" }
    name { "Sample Name" }
    sort_order { 1 }
  end
end
