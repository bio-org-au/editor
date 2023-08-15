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
# Loader Name entity
class Loader::Name::BulkSearchAcceptedOrExcludedOnlyAndNotDrafted
  attr_reader :search

  def initialize(search_s, batch_id)
    @batch_id = batch_id
    @search_s = search_s
    @search = bulk_processing_search
  end

  def bulk_processing_search
    if @search_s.match(/\Afamily:/i)
      family_string = @search_s.sub(/\Afamily: */i, "")
      search = Loader::Name.family_string_search(family_string)
    else
      search = Loader::Name.bulk_operations_search(@search_s)
    end
    search.joins(:loader_batch)
          .where(loader_batch: { id: @batch_id })
          .where("record_type in ('accepted','excluded')")
          .where("not exists (select null from loader_name_match match where match.loader_name_id = loader_name.id and drafted)")
          .order(:seq)
  end
end
