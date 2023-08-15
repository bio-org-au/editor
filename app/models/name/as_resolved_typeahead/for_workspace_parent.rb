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

# Work out the typeahead params for the parent name field.
class Name::AsResolvedTypeahead::ForWorkspaceParent
  include Resolvable
  attr_reader :value

  def initialize(id_string, param_text)
    Rails.logger.debug("initialize")
    @text = param_text.sub(/ *-.*\z/, "")
    @text.rstrip!
    @id_string = id_string
    @field_name = "parent name"
    run
  end

  def run
    no_found if @id_string.blank?

    tree_version_element = TreeVersionElement.find(@id_string)
    return unless tree_version_element.present?

    no_found if @text != tree_version_element.tree_element.simple_name
    @value = tree_version_element.element_link
  end

  def no_found
    @value = ""
    raise "please choose #{@field_name} from suggestions, match not found."
  end
end
