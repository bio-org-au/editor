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
class NameAsCopierWithAllInstancesSimpleTest < ActiveSupport::TestCase
  setup do
    stub_it
  end

  def stub_it
    stub_request(:get, %r{#{path}/[0-9]{8,}/api/name-strings})
      .with(headers: headers)
      .to_return(status: 200, body: return_body.to_json, headers: {})
  end

  def return_body
    {
      class: "silly name class",
      _links: {
        permalink: []
      },
      name_element: "redundant name element for id 960477440",
      action: "unnecessary action",
      result: return_body_result
    }
  end

  def return_body_result
    {
      fullMarkedUpName: "full marked up name for id 960477440",
      simpleMarkedUpName: "simple marked up name for id 960477440",
      fullName: "full name for id 960477440",
      simpleName: "simple name for id 960477440"
    }
  end

  def path
    "http://localhost:9090/nsl/services/rest/name/apni"
  end

  def headers
    { "Accept" => "text/json",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "User-Agent" => /rest-client.*ruby.*/ }
  end

  test "copy name with all instances" do
    test1
    test2
    test3
    test4
    test5
  end

  def test1
    @before = Name.count
    @master_name = Name::AsCopier.find(names(:a_genus_with_two_instances).id)
    @dummy_name_element = "xyz"
    @dummy_username = "fred"
  end

  def test2
    @master_instances_before = @master_name.instances.size
    @copied_name = @master_name.copy_with_all_instances(
      @dummy_name_element,
      @dummy_username
    )
  end

  def test3
    @after = Name.count
    @copied_instances_after = @copied_name.instances.size
  end

  def test4
    assert_equal @before + 1, @after, "There should be one extra name."
    assert_equal @master_instances_before,
                 @copied_instances_after,
                 "New name should have instances."
  end

  def test5
    assert_match @dummy_name_element, @copied_name.name_element
    assert_equal @dummy_username, @copied_name.created_by
    assert_equal @dummy_username, @copied_name.updated_by
  end
end
