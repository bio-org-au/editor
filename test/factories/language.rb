# == Schema Information
#
# Table name: language
#
#  id           :bigint           not null, primary key
#  iso6391code  :string(2)
#  iso6393code  :string(3)        not null
#  lock_version :bigint           default(0), not null
#  name         :string(50)       not null
#
# Indexes
#
#  uk_g8hr207ijpxlwu10pewyo65gv  (name) UNIQUE
#  uk_hghw87nl0ho38f166atlpw2hy  (iso6391code) UNIQUE
#  uk_rpsahneqboogcki6p1bpygsua  (iso6393code) UNIQUE
#
FactoryBot.define do
  factory :language do
    lock_version { 1 }
    sequence(:iso6391code) {|n| "#{n}" }
    sequence(:iso6393code) {|n| "#{n}" }
    sequence(:name) {|n| "Language Name #{n}" }
  end
end
