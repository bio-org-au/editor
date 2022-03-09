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
# Field abbreviations available for building predicates
class Search::Reference::FieldAbbrev
  ABBREVS = {
    "c:" => "citation:",
    "ct:" => "citation-text:",
    "t:" => "title:",
    "ti:" => "title:",
    "ty:" => "type:",
    "ref-type:" => "type:",
    "rt:" => "type:",
    "a:" => "author:",
    "y:" => "year:",
    "iso-publication-date:" => "published-in-or-on:",
    "date:" => "published-in-or-on:",
    "iso:" => "published-in-or-on:",
    "date-matches:" => "iso-pub-date-matches:",
    "pd:" => "publication-date:",
    "is-duplicate:" => "is-a-duplicate:",
    "duplicate:" => "is-a-duplicate:",
    "page:" => "pages:",
  }.freeze
end
