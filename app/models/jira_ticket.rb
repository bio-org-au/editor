# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# SessionUser model - not an active record.
class JiraTicket < ActiveType::Object
  EMAIL = Rails.application.credentials.jira_email
  API_TOKEN = Rails.application.credentials.jira_token

  attr_reader :tickets, :results
  attr_accessor :keys

  attribute :key, :string
  attribute :status, :string

  def self.token
    API_TOKEN
  end

  def self.find(key)
    @results.slice(key.upcase)
  end

  def self.find_status(key)
    @results[key.upcase]
  end

  def self.keys
    @keys
  end

  def self.keys=(array_of_keys)
    @keys = array_of_keys
  end
  
  def self.keys_to_query=(list_of_keys_to_query)
    @keys_to_query = list_of_keys_to_query
  end
  
  def self.jql(keys_array)
    "key in (#{keys_array.join(', ')})"
  end

  # The API limits results to 100 - annoying
  # The API methods for getting more pages of results is a PITA
  # We send 100 keys at a time....
  def self.query_keys
    uri = URI("https://ibis-cloud.atlassian.net/rest/api/3/search/jql")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    limit = 100
    offset = 0
    keys_subset = @keys.first(100)
    accumulated_results_array = []
    while keys_subset.present?
      body = {jql: self.jql(keys_subset),
              maxResults: 100,
              fields: ["status"]}.to_json

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Basic " + Base64.strict_encode64("#{EMAIL}:#{API_TOKEN}")
      request["Accept"]        = "application/json"
      request["Content-Type"]  = "application/json"
      request.body = body
      response = http.request(request)
      latest_array =  ((JSON.parse(response.body))["issues"].collect {|issue| {"#{issue['key']}" =>  "#{issue['fields']['status']['name']}"}})
      accumulated_results_array =  accumulated_results_array.concat(latest_array)
      offset = offset + limit
      keys_subset = @keys[offset, limit]
    end
    @results = accumulated_results_array.reduce({}, :merge)
  end

  def self.results
    @results || {}
  end

  def self.yaml_for_year(year)
    if File.exist?("config/history/changes-#{year}.yml")
      YAML.load_file("config/history/changes-#{year}.yml")
    else
      {}
    end
  end

  def self.keys_for_year(year)
    yaml_for_year(year)
      .collect {|year_entry| "#{year_entry[:jira_project]||'NSL'}-#{year_entry[:jira_id]}"}
      .reject { |item| item.nil? || item.empty? || item.match(/NSL-\z/)}
      .sort
      .uniq
  end
end
