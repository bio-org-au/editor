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

# Batch Statistics report
# Returns a hash
class Loader::Batch::Stats::ForAllNames::Drafted
  def initialize(core_search)
    @core_search = core_search
  end

  def report
    {
      accepted_or_excuded_drafted: accepted_or_excluded_drafted,
    }
  end

  def accepted_or_excluded_drafted
    @core_search.where("record_type in ('accepted','excluded')")
                .joins(:loader_name_matches)
                .where({ loader_name_match:
                           { drafted: true } })
                .count
  end
end
