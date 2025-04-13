FactoryBot.define do
  factory :delayed_job do
    lock_version { 1 }
    locked_by { "Sample Locked by" }
    queue { "Sample Queue" }
  end
end
