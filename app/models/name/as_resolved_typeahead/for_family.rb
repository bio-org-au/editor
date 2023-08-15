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
#   Identify a parent name entered into or selected into a typeahead.
class Name::AsResolvedTypeahead::ForFamily
  include Resolvable
  attr_reader :value

  def initialize(id_string, param_text, field_name)
    @text = extract_delimited_string(param_text)
    @text.rstrip! unless @text.blank?
    @id_string = id_string
    @field_name = field_name
    run
  end

  def run
    case resolve(@id_string, @text)
    when NO_ID_OR_TEXT, ID_ONLY # assume delete
      raise "please choose family from suggestions"
    when TEXT_ONLY
      text_only
    when ID_AND_TEXT
      id_and_text
    else
      raise "please check the #{@field_name}"
    end
  end

  def text_only
    possibles = Name.lower_full_name_like(@text).not_common_or_cultivar
                    .not_a_duplicate
    case possibles.size
    when 0
      zero_possibles_for_text
    when 1
      @value = possibles.first.id
    else
      raise "please choose #{@field_name} from suggestions (more than 1 match)"
    end
  end

  def zero_possibles_for_text
    zero_possibles
  end

  def zero_possibles
    possibles = Name.lower_full_name_like(@text + "%").not_common_or_cultivar
                    .not_a_duplicate
    case possibles.size
    when 1
      @value = possibles.first.id
    else
      raise "please choose #{@field_name} from suggestions"
    end
  end

  def id_and_text
    possibles = Name.lower_full_name_like(@text).not_common_or_cultivar
                    .not_a_duplicate
    case possibles.size
    when 0
      zero_possibles_for_id_and_text
    when 1
      @value = possibles.first.id
    else
      two_or_more_possibles_for_id_and_text
    end
  end

  def zero_possibles_for_id_and_text
    zero_possibles
  end

  def two_or_more_possibles_for_id_and_text
    possibles_with_id = Name
                        .where(id: @id_string.to_i)
                        .lower_full_name_like(@text)
                        .not_a_duplicate
    raise "please choose #{@field_name} from suggestions (> 1 match)" unless possibles_with_id.size == 1

    @value = possibles_with_id.first.id
  end
end
