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
class Loader::Batch::Stats::ForAllNames::InstancesBreakdown
  def initialize(core_search)
    @core_search = core_search
  end

  def report
    { accepted_with_standalone_created: accepted_with_standalone_created,
      accepted_with_standalone_found: accepted_with_standalone_found,
      excluded_with_standalone_created: excluded_with_standalone_created,
      excluded_with_standalone_found: excluded_with_standalone_found,
      synonym_with_cross_ref_created: synonym_with_cross_ref_created,
      synonym_with_cross_ref_found: synonym_with_cross_ref_found,
      misapp_with_cross_ref_created: misapp_with_cross_ref_created,
      misapp_with_cross_ref_found: misapp_with_cross_ref_found }
  end

  def accepted_with_standalone_created
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .where({ loader_name_match:
                           { standalone_instance_created: true } })
                .count
  end

  def excluded_with_standalone_created
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .where({ loader_name_match:
                           { standalone_instance_created: true } })
                .count
  end

  def accepted_with_standalone_found
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .where({ loader_name_matches:
                         { standalone_instance_found: true } })
                .count
  end

  def excluded_with_standalone_found
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .where({ loader_name_match:
                         { standalone_instance_found: true } })
                .count
  end

  def synonym_with_cross_ref_created
    @core_search.where("record_type = 'synonym'")
                .joins(:loader_name_matches)
                .where({ loader_name_matches:
                         { relationship_instance_created: true } })
                .count
  end

  def synonym_with_cross_ref_found
    @core_search.where("record_type = 'synonym'")
                .joins(:loader_name_matches)
                .where({ loader_name_matches:
                         { relationship_instance_found: true } })
                .count
  end

  def misapp_with_cross_ref_created
    @core_search.where("record_type = 'misapplied'")
                .joins(:loader_name_matches)
                .where({ loader_name_matches:
                         { relationship_instance_created: true } })
                .count
  end

  def misapp_with_cross_ref_found
    @core_search.where("record_type = 'misapplied'")
                .joins(:loader_name_matches)
                .where({ loader_name_matches:
                         { relationship_instance_found: true } })
                .count
  end
end
