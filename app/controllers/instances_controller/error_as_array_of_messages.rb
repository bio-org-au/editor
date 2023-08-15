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

#   Instance controller class
class InstancesController
  # Massage error object into a simple array of messages
  class ErrorAsArrayOfMessages
    def initialize(error)
      @raw = error
    end

    def error_array
      error_count = @raw.try("record").try("errors").try("size")
      error_array = []
      if @raw.try("record").nil? || @raw.try("size") == 1 || error_count == 1
        error_array.push(@raw.to_s)
      else
        @raw.try("record").try("errors").try("full_messages").each do |fm|
          error_array.push(fm)
        end
      end
      error_array
    end
  end
end
