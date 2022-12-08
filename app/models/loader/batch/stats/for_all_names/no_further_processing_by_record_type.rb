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
class Loader::Batch::Stats::ForAllNames::NoFurtherProcessingByRecordType
  def initialize(core_search)
    @core_search = core_search
  end

  def report
    { heading: no_further_processing_headings,
      accepted: no_further_processing_accepteds,
      excluded: no_further_processing_excludeds,
      synonym: no_further_processing_synonyms,
      misapplied: no_further_processing_misapplieds,
      total: no_further_processing_total }
  end

  def no_further_processing_total
    @core_search.where(" no_further_processing
                      or (select no_further_processing
                            from loader_name p
                           where p.id = loader_name.parent_id)").count
  end

  def no_further_processing_accepteds
    @core_search.where("record_type = 'accepted'
                       and no_further_processing").count
  end

  def no_further_processing_headings
    @core_search.where("record_type = 'heading'
                       and no_further_processing").count
  end

  def no_further_processing_excludeds
    @core_search.where("record_type = 'excluded'
                       and no_further_processing").count
  end

  def no_further_processing_synonyms
    @core_search.where("record_type = 'synonym' and
                      (no_further_processing or
                      (select no_further_processing
                         from loader_name p
                        where p.id = loader_name.parent_id))").count
  end

  def no_further_processing_misapplieds
    @core_search.where("record_type = 'misapplied' and
                      (no_further_processing or
                      (select no_further_processing
                         from loader_name p
                        where p.id = loader_name.parent_id))").count
  end
end
