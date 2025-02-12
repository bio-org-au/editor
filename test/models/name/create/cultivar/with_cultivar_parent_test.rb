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
require "test_helper"

# Single name model test.
# NSL-3576
class NameCreateCultivarWithCultivarParentTest < ActiveSupport::TestCase
  def setup
    setup1
    setup2
  end

  def setup1
    name_type = name_types(:cultivar)
    name_rank = name_ranks(:unranked)
    name_status = name_statuses(:na)
    @name_element = "newcultname"
    @name_params = { "name_type_id" => name_type.id.to_s,
                     "name_rank_id" => name_rank.id.to_s,
                     "name_status_id" => name_status.id.to_s,
                     "name_element" => @name_element,
                     "verbatim_rank" => "" }
    @parent = names(:a_cultivar)
  end

  def address
    "http://localhost:9090/nsl/services/rest/name/apni/"
  end

  def setup2
    stub_request(:get, %r{#{address}[0-9]{1,}/api/name-strings})
      .with(headers: { "Accept" => "text/json",
                       "Accept-Encoding" =>
                       "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Host"=>'localhost:9090',
                       "User-Agent" => /rest-client.*ruby.*/ })
      .to_return(status: 200, body: body, headers: {})
  end

  def body
    %({ "class": "silly name class",
    "_links": { "permalink": [ ] },
    "name_element": "redundant name element for id 960477440",
    "action": "unnecessary action",
    "result": {
        "fullMarkedUpName": "full marked up name for id 960477440",
        "simpleMarkedUpName": "simple marked up name for id 960477440",
        "fullName": "full name for id 960477440",
        "simpleName": "simple name for id 960477440" } })
  end

  test "simple" do
    typeahead_params =
      { "parent_typeahead" => "#{@parent.full_name} | Species",
        "parent_id" => @parent.id.to_s,
        "verbatim_rank" => "sdfdf" }
    name = Name::AsEdited.create(@name_params, typeahead_params, "fred")
    assert name.name_element == @name_element
    assert name.name_path == "Plantae/Magnoliophyta/a_family/a_genus/#{@parent.name_element}/#{@name_element}"
    assert name.valid?,
           "Name should be valid. Errs: #{name.errors.full_messages.join('; ')}"
  end
end
