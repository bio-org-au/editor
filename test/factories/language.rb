FactoryBot.define do
  factory :language do
    lock_version { 1 }
    sequence(:iso6391code) {|n| "#{n}" }
    sequence(:iso6393code) {|n| "#{n}" }
    sequence(:name) {|n| "Language Name #{n}" }
  end
end
