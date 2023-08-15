# frozen_string_literal: true

#   Copyright 2018 Australian National Botanic Gardens
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
# Handle an manipulate profile data for trees
class Tree::ProfileData
  attr_reader :profile_data

  def initialize(user, tree_version, profile_data)
    @current_user = user
    @tree_version = tree_version
    @profile_data = safe_profile(profile_data)
  end

  def safe_profile(profile_data)
    profile_data || {}
  end

  def update_comment(comment)
    update_profile(@tree_version.comment_key, comment)
  end

  def update_distribution(distribution)
    dist_str = distribution&.join(", ") || ""
    update_profile(@tree_version.distribution_key, dist_str)
  end

  def update_profile(key, value)
    if value && key
      if value.blank?
        @profile_data.delete(key)
      else
        @profile_data[key] = { value: value,
                               updated_by: @current_user.username,
                               updated_at: Time.now.utc.iso8601 }
      end
    end
    @profile_data
  end
end
