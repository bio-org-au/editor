# Doing this because we want Jenkins to grab the app version for the build
# processing and we need rails to display the version number in the app.
#
# Turns out, it was easier to use ruby to pull the info from a Jenkins-friendly
# file than for Jenkins to extract the info from a ruby file.
begin
  Rails.configuration.version_file_path = "config/version.properties"
  puts "Reading the app version from the #{Rails.configuration.version_file_path} file"
  version = "unknown"
  a = File.readlines(Rails.configuration.version_file_path)
  a.select { |line| line =~ /appversion/ }
  b = a.select { |line| line =~ /appversion/ }
  version = b.first.chomp.split("=").last
  puts("Configuring version #{version} of the app.")
  Rails.configuration.version = version
rescue StandardError => e
  puts e
  puts "Warning: config couldn't find the app version from the expected file."
  puts "Action: check #{Rails.configuration.version_file_path} exists and has an 'appversion=...' line"
  Rails.configuration.version = "unknown"
end
