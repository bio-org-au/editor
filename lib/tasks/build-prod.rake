desc "build prod"
task :build_prod do
  sh "RAILS_ENV=production bundle exec rake assets:precompile RAILS_RELATIVE_URL_ROOT='/nsl/editor'"
  sh "echo 'Modify prod config with time utc'"
  sh "ed config/environments/production.rb <build_prod/config-prod.ed"
  sh "echo 'Modify services build partial with build timestamp'"
  sh "ed app/views/services/_build.html.erb <build_prod/build-timestamp.ed"
  # sh "echo rm node_modules"
  # sh "rm -rf node_modules"
  sh "echo rm tests"
  sh "rm -rf test"
  sh "echo clear logs"
  sh "rails log:clear"
  sh "echo remove git files"
  sh "rm -rf .git"
  sh "rm -rf .github"
  sh "rm -rf .gitignore"
  puts "Ready to tar"
end

