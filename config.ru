# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

# Necessary to make sub url work.
# See
# https://groups.google.com/forum/?utm_medium=email&utm_source=footer#!msg/rubyonrails-talk/0MnKcwkNIGY/X7WBN6ptBgAJ
# https://github.com/rails/rails/issues/24393
# See https://github.com/rails/rails/pull/24412
map Rails.application.config.action_controller.relative_url_root || "/" do
  run Rails.application
  Rails.application.load_server
end
