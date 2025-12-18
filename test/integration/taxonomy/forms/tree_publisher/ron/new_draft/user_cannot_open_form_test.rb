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

# Single search controller test.
#
# Note: 
#   xhr: true
#
# stopped this error in test: 
#
# ActionController::InvalidCrossOriginRequest: Security warning: 
#   an embedded <script> tag on another site requested protected JavaScript.
class TaxFormsTreePubRONNewDraftUserCannotOpenFormTest < ActionController::TestCase
  tests TreeVersionsController

  def setup
  end

  # We need to have no draft versions for this test case
  def publish_existing_draft
    draft_tree_version = tree_versions(:ron_draft_version)
    draft_tree_version.published = true
    draft_tree_version.save!
  end

  test "RON tree publisher user cannot open new draft form for read only tree" do
    user = users(:ron_tax_publisher)
    error = assert_raises(RuntimeError) {
      get(:new_draft,
        params: {tree_id: trees(:RON)},
        format: :js,
        xhr: true,
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"]})
    }
    assert_equal 'RON tree is read only - cannot create any drafts', error.message
  end
end
