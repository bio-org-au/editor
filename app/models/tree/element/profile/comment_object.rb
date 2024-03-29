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
# Tree Element Profile jsonb component
class Tree::Element::Profile::CommentObject
  def initialize(username, text)
    @username = username
    @text = text
  end

  def as_hash
    h = {}
    h["value"] = @text
    h["created_at"] = h["updated_at"] = Time.now
    h["created_by"] = h["updated_by"] = @username
    h
  end
end
