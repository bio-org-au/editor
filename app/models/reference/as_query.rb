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

# Reference as a Query
class Reference::AsQuery < Reference
  def self.options
    {
      "citation" => "with citation",
      "t" => "with title",
      "ra" => "with author name",
      "id" => "with ID",
      "ids" => "with ID in list",
      "author-id" => "author ID",
      "pt" => "with parent title",
      "y" => "with year",
      "vol" => "with volume",
      "p" => "parent id",
      "rp" => "parent id",
      "bhl" => "BHL",
      "duplicate" => "is a duplicate",
      "pd" => "has pub date",
      "ref-type" => "with type",
      "with-comments" => "with comments",
      "with-comments-by" => "with comments by",
      "cr-a" => "created since",
      "cr-b" => "created before",
      "upd-a" => "updated since",
      "upd-b" => "updated before",
      "no-year-no-pub-date" => "no year/pub date"
    }
  end
end
