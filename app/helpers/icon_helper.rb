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

# Help display icons
module IconHelper
  def menu_icon(_entity)
    "" # entity_icon(entity, 10,6)
  end

  def record_icon(entity)
    entity_icon(entity, 13, 7)
  end

  def entity_icon(entity, height = 10, width = 10)
    content_tag(:svg,
                tag(:polygon,
                    class: "svgpolygon",
                    points: "2,3, #{2 + width},3,  #{2 + width},23  2,23",
                    fill: color_for(entity)),
                class: "icon name-icon", height: "#{height}px",
                width: "#{width}px", xmlns: "http://www.w3.org/2000/svg",
                title: entity.capitalize)
  end

  def color_for(entity)
    case entity
    when "name" then "rgba(102,183,39,1.0)"
    when "author" then "rgba(52,114,218,1.0)"
    when "reference" then "rgba(245,172,0,1.0)"
    when "instance" then "rgba(197,151,203,1.0)"
    when "orchid" then "rgba(121,7,242,1.0)"
    else "rgba(197,151,203,1.0)"
    end
  end

  def editor_icon(icon, text = "", html_options = {})
    html_options[:class] = icon_content_class(icon, html_options)
    html = if text.blank?
             content_tag(:i, nil, html_options)
           else
             "#{content_tag(:i, nil, html_options)} #{text}"
           end
    html.html_safe
  end

  def external_link_square_icon
    editor_icon('external-link-square')
  end

  def icon_content_class(icon, html_options = {})
    if html_options.key?(:class)
      "fa fa-#{icon} #{html_options[:class]}"
    else
      "fa fa-#{icon}"
    end
  end

  def search_icon_on_tab
    editor_icon("search")
  end

  def gray_search_icon
    editor_icon("search", "", class: "darkgray")
  end
end
