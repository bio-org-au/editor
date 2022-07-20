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

# Single Reference model test.
class WholeRecordChangedVolumeTest < ActiveSupport::TestCase
  setup do
    @reference = Reference::AsEdited.find(
      references(:for_whole_record_change_detection).id
    )

    @params = { "title" => @reference.title,
                "iso_publication_date" => @reference.iso_publication_date,
                "volume" => "#{@reference.volume || ''}x",
                "pages" => @reference.pages,
                "edition" => @reference.edition,
                "ref_author_role_id" => @reference.ref_author_role_id,
                "published" => @reference.published,
                "publication_date" => @reference.publication_date,
                "notes" => @reference.notes,
                "ref_type_id" => @reference.ref_type_id }

    @typeahead_params = { "parent_id" => @reference.parent_id,
                          "parent_typeahead" => @reference.parent.citation,
                          "author_id" => @reference.author_id,
                          "author_typeahead" => @reference.author.name }
    stub_it
  end

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
                 %r{http://#{a}/nsl/services/rest/#{b}/apni/[0-9][0-9]*/api/#{c}})
      .with(headers: { "Accept" => "text/json",
                       "Accept-Encoding" =>
                       "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "User-Agent" => "Ruby" })
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

  test "realistic form submission" do
    assert @reference.update_if_changed(@params,
                                        @typeahead_params,
                                        "a user"),
           "The reference has changed so it should be updated."
    changed_reference = Reference.find_by(id: @reference.id)
    assert @reference.created_at < changed_reference.updated_at,
           "Reference updated at should have changed."
    assert @reference.updated_by.match("a user"),
           "Reference updated by should have been set."
  end
end
