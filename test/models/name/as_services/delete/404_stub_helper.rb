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

# utility methods
def a
  ""
end

def b
  "nsl.services.name.apni.[1-9][0-9]{8,}.*reason=404"
end

def agent
  "rest-client/2.0.0 (darwin16.1.0 x86_64) ruby/2.3.0p0"
end

def stub_it
  stub_request(:delete, /#{a}#{b}/)
    .with(headers: { "Accept" => "application/json",
                     "Accept-Encoding" => "gzip, deflate",
                     "Host" => "localhost:9090",
                     "User-Agent" => agent })
    .to_return(status: 404, body: body, headers: {})
end

def body
  { "action" => "delete",
    "errors" => ["The Instance was not found."] }.to_json
end
