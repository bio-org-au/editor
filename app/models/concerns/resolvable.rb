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
module Resolvable

  extend ActiveSupport::Concern

  NO_ID_OR_TEXT = :no_id_or_text
  ID_AND_TEXT = :id_and_text
  ID_ONLY = :id_only
  TEXT_ONLY = :text_only

  def resolve(id_string, text)
    if id_string.blank?
      no_id(text)
    else
      id_present(text)
    end
  end

  def no_id(text)
    if text.blank?
      NO_ID_OR_TEXT
    else # text is present
      TEXT_ONLY
    end
  end

  def id_present(text)
    if text.blank?
      ID_ONLY # assume intention is to remove the field value
    else # text is present
      ID_AND_TEXT
    end
  end

  # param_text can be empty (signalling removal) or of the form:
  # 
  #      text for matching record | extra info for user
  #
  # We need to extract the first part 
  # ie. "text for matching record"
  # from param_text while allowing for the empty string
  def extract_delimited_string(param_text)
    return param_text if param_text.blank?
    param_text.split('|').first
  end

end
