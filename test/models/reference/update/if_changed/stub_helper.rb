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

def a
  "localhost:9090"
end

def b
  "reference"
end

def c
  "citation-strings"
end

def stub_it
  stub_request(:get,
               %r{http://#{a}/nsl/services/rest/#{b}/apni/[0-9]{8,}/api/#{c}})
    .with(headers: { "Accept" => "text/json",
                     "Accept-Encoding" =>
                     "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                     "User-Agent" => /rest-client.*ruby.*/ })
    .to_return(status: 200, body: body.to_json, headers: {})
end

def body
  %({"action": "citation-strings",
  "reference": { "_links": { "permalink": [] }, "citation":
  "Hasskarl, J.C. (Oct. 1855), Retzia sive Observationes in ...Julium 1855",
  "citationAuthYear": "Hassk., null",
  "citationHtml": "Hasskarl, J.C. (Oct. 1855), Retzia sive ...Julium 1855",
  "class": "au.org.biodiversity.nsl.Reference" },
  "result": { "citation": "Hasskarl, J.C. (Oct. 1855), ...Julium 1855",
  "citationHtml": "Hasskarl, J.C. (Oct. 1855), Retzia...Julium 1855" } })
end
