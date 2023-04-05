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


#  We need to place Orchids on a draft tree.
class Loader::Batch::SummaryCounts::AsStatusReporter::ForAcceptedNames
  def initialize(search_string, batch_id)
    @search_string = search_string.downcase.gsub(/\*/,'%')
    @batch_id = batch_id
  end

  def report
    { search: {batch_id: @batch_id,
               search_string: @search_string,
               reported_at: Time.now.strftime("%d-%b-%Y %H:%M:%S"),
               name_category: 'Accepted'},
      core: { heading_records: heading_records,
              accepted_family: accepted_families,
              accepted_genera: accepted_genera,
              accepted_species_and_below: accepted_species_and_below,
              synonym: synonyms,
              misapplied: misapplieds,
              hybrid_cross: hybrid_crosses,
              intergrade: intergrades,
              accepted_with_distribution: accepted_with_distribution,
              taxonomy_comments: taxonomy_comments,
              excluded_names: excluded_names,
              total: core_search.size,
              },
    }
  end

  def core_search
    if @search_string == '%' then
      Loader::Name.where(loader_batch_id: @batch_id)
    else
      Loader::Name.bulk_operations_search(@search_string).where(loader_batch_id: @batch_id)
    end
  end

  def accepted_species_and_below
    arg = "record_type = 'accepted' and not excluded and not doubtful and rank in ('species','infraspecific')"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def heading_records
    arg = "record_type = 'heading'" 
    {count: core_search.where(arg).count,
     text: arg}
  end

  def accepted_families
    arg = "record_type = 'accepted' and not excluded and not doubtful and rank = 'family'"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def accepted_genera
    arg = "record_type = 'accepted' and not excluded and not doubtful and rank = 'genus'"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def excluded_names
    arg = "record_type = 'excluded'"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def taxonomy_comments
    arg = "record_type in ('accepted','excluded') and comment is not null"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def accepted_with_distribution
    arg = "record_type = 'accepted' and distribution is not null"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def synonyms
    arg = "record_type = 'synonym'"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def misapplieds
    arg = "record_type = 'misapplied'"
    {count: core_search.where(arg).count,
     text: arg}
  end

  def hybrid_crosses
    {count: core_search.where("hybrid_flag = 'hybrid'").count,
     text: "hybrid_flag = 'hybrid'"}
  end

  def intergrades
    {count: core_search.where("hybrid_flag = 'intergrade'").count,
     text: "hybrid_flag = 'intergrade'"}
  end
end
