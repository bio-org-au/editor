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
  "http://localhost:9090"
end

def b
  "/nsl/services/rest/instance/apni/666/api/delete?apiKey=test-api-key&reason=Edit"
end

def agent
  "rest-client/2.0.0 (darwin16.1.0 x86_64) ruby/2.3.0p0"
end

def stub_it
  stub_request(:delete, "#{a}#{b}")
    .with(headers: { "Accept" => "application/json",
                     "Accept-Encoding" => "gzip, deflate",
                     "Host" => "localhost:9090",
                     "User-Agent" => agent })
    .to_return(status: 200, body: body, headers: {})
end

def body
  { "instance" =>
     { "class" => "au.org.biodiversity.nsl.Instance",
       "_links" => body_links,
       "instanceType" => "taxonomic synonym",
       "protologue" => false,
       "citation" => leach,
       "citationHtml" => leach_html },
    "action" => "delete",
    "ok" => false,
    "errors" => errors }.to_json
end

def errors
  ["There are 1 instances that cite this.",
   "There are 1 instances that say this cites it."]
end

def body_links
  { "permalink" =>
    { "link" =>
        "http://localhost:8080/nsl/mapper/boa/instance/apni/819227",
      "preferred" => true,
      "resources" => 1 } }
end

def leach
  "Leach, G.J. (1986), A Revision of the Genus Angophora (Myrtaceae).\
    Telopea 2(6)"
end

def leach_html
  "Leach, G.J. (1986), A Revision of the Genus \
    Angophora (Myrtaceae). <i>Telopea</i> 2(6)"
end
