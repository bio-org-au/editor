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

# Help for Tabs display
module TabsHelper
  def user_profile_tab_name
    current_registered_user.available_product_from_roles&.name
  end

  def increment_tab_index(increment = 1)
    @tab_index ||= 1
    @tab_index += increment
  end

  def tab_index(offset = 0)
    tabi = @tab_index || 1
    tabi + offset
  end

  def product_tab_text(entity_type, tab_type, default_text)
    return default_text unless Rails.configuration.try('multi_product_tabs_enabled')

    default_text
  end

  def tab_available?(tabs_array, tab_name)
    return true unless Rails.configuration.try('multi_product_tabs_enabled')
    return true if product_context_service.available_contexts.blank?

    tabs_array.include?(tab_name)
  end
end
