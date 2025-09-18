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
#   Names are central to the NSL.
class Names::Typeaheads::ForWorkspaceParentNameController < ApplicationController
  def index
    authorize! :names_typeahead_for_workspace_parent, @working_draft,
      :message => "Not authorized to open #{@working_draft.tree.name} typeahead"
    typeahead = Name::AsTypeahead::ForWorkspaceParentName
                .new(params, @working_draft)
    render json: typeahead.suggestions
  end

  private

  def typeahead_params
    params.permit(:term)
  end
end
