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
class Search::Loader::Name::FieldAbbrev
  ABBREVS = {
    "loader-batch:" => "batch:",
    "loader-batch-id:" => "batch:",
    "batch-id:" => "batch:",
    "name:" => "scientific-name:",
    "accepted-with-syn:" => "name-with-syn:",
    "acc:" => "name-with-syn:",
    "exc:" => "excluded-with-syn:",
    "excluded:" => "excluded-with-syn:",
    "is-synonym:" => "is-syn:",
    "synonym:" => "is-syn:",
    "concept-note:" => "comment:",
    "remark-to-reviewers:" => "remark:",
    "scientific-name:" => "simple-name:",
    "raw-ids:" => "raw-id:",
    "manually-created:" => "created-manually:",
    "cm:" => "created-manually:",
    "mc:" => "created-manually:",
  }.freeze
end
