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
# Author Editing
class Author::AsEdited < Author::AsTypeahead
  include AuthorAuthorResolvable
  AED = "Author::AsEdited:"
  def self.create(params, typeahead_params, username)
    author = Author::AsEdited.new(params)
    author.resolve_typeahead_params(typeahead_params)
    if author.save_with_username(username)
      author
    else
      raise author.errors.full_messages.first.to_s
    end
  end

  def update_if_changed(params, typeahead_params, username)
    # strip_attributes is in place and should make this unnecessary
    # but it's not working in the way I expect
    params.keys.each { |key| params[key] = nil if params[key] == '' } 
    assign_attributes(params)
    resolve_typeahead_params(typeahead_params)
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def resolve_typeahead_params(params)
    resolve_author(params, "duplicate_of", self)
  end
end
