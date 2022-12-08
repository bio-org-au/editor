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
class Loader::Batch::Stats::ForAllNames::MatchedWithDecision
  def initialize(core_search)
    @core_search = core_search
  end

  def report
    { accepted_batch_default_reference: accepted_choice_default_ref,
      accepted_use_existing_instance: accepted_choice_use_existing_instance,
      accepted_copy_and_append: accepted_choice_copy_and_append,
      total_accepted_choice_made: accepted_choice_made,
      accepted_no_choice_made: accepted_no_choice_made,
      excluded_batch_default_reference: excluded_choice_default_ref,
      excluded_use_existing_instance: excluded_choice_use_existing_instance,
      excluded_copy_and_append: excluded_choice_copy_and_append,
      total_excluded_choice_made: excluded_choice_made,
      excluded_no_choice_made: excluded_no_choice_made }
  end

  def accepted_choice_default_ref
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .where("loader_name_match.use_batch_default_reference = true")
                .where(" instance_choice_confirmed ")
                .count
  end

  def accepted_choice_use_existing_instance
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .where("loader_name_match.use_existing_instance = true")
                .where(" instance_choice_confirmed ")
                .count
  end

  def accepted_choice_copy_and_append
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .where("copy_append_from_existing_use_batch_def_ref = true")
                .where(" instance_choice_confirmed ")
                .count
  end

  def accepted_no_choice_made
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .where("not loader_name_match.use_batch_default_reference")
                .where(" not loader_name_match.use_existing_instance ")
                .where(" not copy_append_from_existing_use_batch_def_ref ")
                .where(" not instance_choice_confirmed ")
                .count
  end

  def accepted_choice_made
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .where(" instance_choice_confirmed ")
                .count
  end

  def excluded_choice_default_ref
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .where("loader_name_match.use_batch_default_reference = true")
                .count
  end

  def excluded_choice_use_existing_instance
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .where("loader_name_match.use_existing_instance = true")
                .count
  end

  def excluded_choice_copy_and_append
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .where("loader_name_match.copy_append_from_existing_use_batch_def_ref = true")
                .count
  end

  def excluded_choice_made
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .where(" instance_choice_confirmed ")
                .count
  end

  def excluded_no_choice_made
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .where("not loader_name_match.use_batch_default_reference")
                .where(" not loader_name_match.use_existing_instance ")
                .where(" not loader_name_match.copy_append_from_existing_use_batch_def_ref ")
                .count
  end
end
