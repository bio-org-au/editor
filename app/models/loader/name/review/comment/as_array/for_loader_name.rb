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

# Review Comments  are associated with a Loader Names:
#
# This class collects the comments associated with a single loader name
#
# The collection is in the results attribute.
#
#
class Loader::Name::Review::Comment::AsArray::ForLoaderName < Array
  attr_reader :results

  def initialize(loader_name, limit = 1000, offset = 0)
    debug("init #{loader_name.simple_name}")
    @results = []
    @already_shown = []
    @loader_name = loader_name
    @count = 0
    @limit = limit
    @sort_by = sort_by
    @offset = offset || 0
    @limit += @offset if @limit < @offset
    find_comments
  end

  def debug(s)
    Rails.logger
      .debug("Loader::Name::Review::Comment::AsArray::ForLoaderName: #{s}")
  end

  def find_comments
    debug "find_comments"
    @count = 1
    find_comments_for_loader_name
    @limited = true if @count > @limit
    @results
  end

  def built_query
    query = @loader_name
            .name_review_comments
            .includes(:batch_reviewer)
            .order(:created_at)
  end

  def find_comments_for_loader_name
    built_query.each do |review_comment|
      if @count < @offset
        @count += 1
      elsif @count < @limit
        @count += 1
        @results.push(review_comment)
      end
      break if @count > @limit
    end
  end
end

