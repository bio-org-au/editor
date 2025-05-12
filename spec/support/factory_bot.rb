# frozen_string_literal: true

require "factory_bot"

RSpec.configure do |config|
  config.include(FactoryBot::Syntax::Methods)
  config.use_transactional_fixtures = false
end
