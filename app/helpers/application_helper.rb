module ApplicationHelper
  def disable_common_cultivar_checkbox
    !(params[:query_on].nil? || params[:query_on].match(/\Aname\z/i))
  end

  def parse_markdown(markdown)
    Kramdown::Document.new(markdown).to_html.html_safe
  end

  def nav_link(text, icon_name)
    "<div class='icon-for-menu'>#{menu_icon(icon_name)}</div>
    <div class='text-for-link'>#{text}</div>".html_safe
  end

  def increment_tab_index(increment = 1)
    @tab_index ||= 1
    @tab_index += increment
  end

  def tab_index(offset = 0)
    tabi = @tab_index || 1
    tabi + offset
  end

  def treated_label(label, treatment = :description)
    case treatment
    when :description
      label.as_field_description
    when :acronym
      label.to_acronym
    else
      label
    end
  end

  def divider
    tag(:hr, class: "divider")
  end

  def lov_select_field(entity,
                       attribute,
                       cache,
                       options,
                       html_attributes,
                       label = "",
                       label_is = :description)
    content_tag(:section,
                select(entity,
                       attribute,
                       cache,
                       options,
                       html_attributes) +
                content_tag(:label,
                            treated_label(label, label_is),
                            class: "inline pull-right"),
                class: "editable-text-field block") +
      tag(:span,
          class: "field-error-message width-90-percent")
  end

  def formatted_timestamp(timestamp_with_timezone)
    l(timestamp_with_timezone, format: :default)
  end

  def as_date(timestamp_with_timezone)
    l(timestamp_with_timezone, format: :as_date)
  end

  def formatted_date(date)
    date
    # date.strftime("%d-%b-%Y")
  end

  def ext_mapper_url
    Rails.configuration.try("mapper_root_url") || Rails.configuration.x.mapper_external.url
  end

  def mapper_link(type, id)
    # this is brittle. Replace with getting the URI from the object or the mapper directly.
    # see name and instance examples below.
    %(<a href="#{ext_mapper_url}#{type}/#{sanitize(ShardConfig.name_space.downcase)}/#{id}" title="#{type.capitalize} #{id}"><i class="fa fa-link"></i></a>).html_safe
  end

  def mapper_instance_link(instance)
    %(<a href="#{ext_mapper_url}#{instance.uri}" title="INSTANCE #{instance.id}"><i class="fa fa-link"></i></a>).html_safe
  end

  def mapper_name_link(name)
    %(<a href="#{ext_mapper_url}#{name.uri}" title="NAME #{name.id}"><i class="fa fa-link"></i></a>).html_safe
  end

  def badge
    return "#{Rails.configuration.try('tag')}" unless Rails.configuration.try("tag").blank?

    case Rails.configuration.try("environment")
    when /\Adev/i
      "Dev Editor"
    when /^test/i
      "Test Editor"
    when /^stag/i
      "Stage Editor"
    when /^prod/i
      "#{ShardConfig.shard_group_name} Editor"
    else
      "#{ShardConfig.shard_group_name} Editor"
    end
  end

  def page_title
    case Rails.configuration.try("environment")
    when /\Adev/i
      "Dev"
    when /^test/i
      "Test"
    when /^stag/i
      "Stage"
    when /^prod/i
      "#{ShardConfig.shard_group_name}"
    else
      "#{ShardConfig.shard_group_name}"
    end + ':' + (params["query_target"] || 'Editor').gsub(/_/,' ').titleize
  end

  def development?
    Rails.configuration.try("environment", /^development/i)
  end
end

# Some specific string methods.
class String
  def as_field_description
    tr("_", " ").gsub(/\bid\b/i, "ID")
  end

  def to_acronym
    tr("_", " ").upcase
  end
end
