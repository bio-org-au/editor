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

# Help display audit information.
module AuditHelper
  def created_by_whom_and_when(record)
    %(Created <span class="purple"
    >#{time_ago_in_words(record.created_at)}&nbsp;ago</span>
    by #{record.created_by.downcase} #{formatted_timestamp(record.created_at)})
  end

  # Only show updated_at if a meaningful time after created_at.
  def updated_by_whom_and_when(record)
    if (record.created_at.to_f / 10).to_i == (record.updated_at.to_f / 10).to_i
      "Not updated since it was created."
    else
      meaningful_update(record)
    end
  end

  def meaningful_update(record)
    %(Last updated
    <span class="purple">#{time_ago_in_words(record.updated_at)}&nbsp;ago
    </span> by #{record.updated_by.downcase} #{formatted_timestamp(
      record.updated_at
    )})
  end

  def meaningful_update_when_no_created_at(record)
    %(Created or last updated
    <span class="purple">#{time_ago_in_words(record.updated_at)}&nbsp;ago
    </span> by #{record.updated_by.downcase} #{formatted_timestamp(
      record.updated_at
    )})
  end

  def published_by_whom_and_when(record)
    %(Published <span class="purple"
    >#{time_ago_in_words(record.published_at)}&nbsp;ago</span>
    by #{record.published_by.downcase} #{formatted_timestamp(record.published_at)})
  end
end
