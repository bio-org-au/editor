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
class NameAsCopierMakeACopySimpleTest < ActiveSupport::TestCase
  setup do
    stub_it
    @before = Name.count
    @master_name = Name::AsCopier.find(names(:a_genus_with_two_instances).id)
    @dummy_name_element = "xyz"
    @dummy_username = "fred"
    @copied_name = @master_name.copy_with_username(
      @dummy_name_element,
      @dummy_username
    )
    @after = Name.count
  end

  def stub_it
    stub_request(:get, %r{#{action}[0-9]{8,}/api/name-strings})
      .with(headers: headers)
      .to_return(status: 200, body: return_body, headers: {})
  end

  def return_body
    %({ "class": "silly name class", "_links": { "permalink": [ ] },
    "name_element": "redundant name element for id",
    "action": "unnecessary action",
    "result": {
        "fullMarkedUpName": "full marked up name for id",
        "simpleMarkedUpName": "simple marked up name for id",
        "fullName": "full name for id",
        "simpleName": "simple name for id"
    } })
  end

  def action
    "http://localhost:9090/nsl/services/rest/name/apni/"
  end

  def headers
    { "Accept" => "text/json",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "User-Agent" => /rest-client.*ruby.*/ }
  end

  test "copy one name" do
    test1
    test2
    test3
    test4
    test5
    test6
  end

  def test1
    assert_equal @before + 1, @after, "There should be one extra name."
    assert_equal @master_name.name_type_id, @copied_name.name_type_id
    assert_equal @master_name.name_rank_id, @copied_name.name_rank_id
    assert_equal @master_name.name_status_id, @copied_name.name_status_id
    assert_equal @master_name.namespace_id, @copied_name.namespace_id
  end

  def test2
    assert_nil @master_name.author_id
    assert_nil @copied_name.author_id
    assert_nil @master_name.base_author_id
    assert_nil @copied_name.base_author_id
    assert_nil @master_name.ex_author_id
    assert_nil @copied_name.ex_author_id
  end

  def test3
    assert_nil @master_name.ex_base_author_id
    assert_nil @copied_name.ex_base_author_id
    assert_nil @master_name.sanctioning_author_id
    assert_nil @copied_name.sanctioning_author_id
  end

  def test4
    assert_equal @master_name.orth_var, @copied_name.orth_var
    assert_equal @master_name.parent_id, @copied_name.parent_id
    assert_nil @master_name.second_parent_id
  end

  def test5
    assert_nil @copied_name.second_parent_id
    assert_nil @master_name.verbatim_rank
    assert_nil @copied_name.verbatim_rank
    assert_match @dummy_name_element, @copied_name.name_element
  end

  def test6
    assert_equal @dummy_username, @copied_name.created_by
    assert_equal @dummy_username, @copied_name.updated_by
  end
end
