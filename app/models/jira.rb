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
class Jira
  attr_reader :key, :status

  URI = "https://ibis-cloud.atlassian.net/rest/api/latest/issue/"
  FIELDS = "fields=status",

           def initialize(key)
             @key = key
             @error = false
             @status = call_api
           end

  def timeout
    Rails.configuration.try("jira_api_timeout") || 10.minute
  end

  def call_api
    Rails.cache.fetch(@key, expires_in: timeout) do
      Rails.logger.debug("Cache block executing for key: #{@key}")
      @response = RestClient.get("#{URI}#{@key}?fields=status",
                                 { Authorization: "Basic #{api_key}" })
      JSON.parse(@response)["fields"]["status"]["name"] unless @error
    end
  rescue StandardError => e
    @error = true
    Rails.logger.error(e.to_s)
  end

  def api_key
    Rails.configuration.try("jira_key")
  end
end
