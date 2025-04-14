# frozen_string_literal: true

# Help for Instance display
module InstancesHelper
  def instance_citation_types_names(instance)
    instance.citations.collect { |c| c.instance_type.name }
  end

  def array_of_counted_types(type_names_array)
    type_names_array.collect.each_with_object(Hash.new(0)) do |o, h|
      h[o] += 1
    end
  end

  def citation_summary(instance)
    array_of_counted_types(instance_citation_types_names(instance))
      .collect { |k, v| pluralize(v, k) }.join(" and ")
  end

  def show_field_as_linked_lookup(label,
                                  linked_entity,
                                  contents_method,
                                  url,
                                  title)
    if linked_entity
      show_field_as_linked_entity(label, linked_entity, contents_method, url,
                                  title)
    else # empty
      show_field_as_not_linked_entity(label)
    end
  end

  def show_field_as_linked_entity(label, linked_entity, contents_method, url,
                                  title)
    content_tag(:section,
                content_tag(:article,
                            content_tag(:a,
                                        linked_entity.send(contents_method),
                                        href: url,
                                        title: title),
                            class: "field-data inline") +
                    field_label(label),
                class: "field-data")
  end

  def show_field_as_not_linked_entity(label)
    content_tag(:section,
                content_tag(:article,
                            content_tag(:span),
                            class: "field-data inline") +
                    field_label(label),
                class: "field-data")
  end

  def field_label(label)
    content_tag(:label,
                label.as_field_description,
                class: "field-label inline pull-right")
  end


  ALLOWED_TABS = %w[tab_show_1 tab_edit tab_edit_profile_v2 tab_edit_notes tab_comments].freeze
  ALLOWED_TABS_TO_OFFER = %w[tab_profile_details tab_edit_profile tab_profile_v2 tab_copy_to_new_profile_v2 tab_batch_loader] .freeze
  def tab_for_instance_type(tab, row_type)
    sanitized_allowed_tabs_to_offer_tab = tab.presence_in(ALLOWED_TABS_TO_OFFER) if @tabs_to_offer.include?(tab)
    tab.presence_in(ALLOWED_TABS) || sanitized_allowed_tabs_to_offer_tab || tab_for_instance_using_row_type(tab, row_type)
  end

  ALLOWED_ROW_TYPES = %w[instance_record instance_as_part_of_concept_record tab_copy_to_new_profile_v2 citing_instance_within_name_search].freeze
  def tab_for_instance_using_row_type(tab, row_type)
    sanitized_row_type = row_type.presence_in(ALLOWED_ROW_TYPES)

    case sanitized_row_type
    when "instance_record"
      tab_for_instance_record(tab)
    when "instance_as_part_of_concept_record"
      tab_for_iapo_concept_record(tab)
    when "citing_instance_within_name_search"
      tab_for_citing_instance_in_name_search(tab)
    else
      "tab_empty"
    end
  end

  def tab_for_instance_record(tab)
    if %w[tab_synonymy tab_synonymy_for_profile_v2 tab_unpublished_citation tab_unpublished_citation_for_profile_v2 tab_classification \
          tab_copy_to_new_reference].include?(tab)
      tab
    else
      "tab_empty"
    end
  end

  # standalone
  def tab_for_iapo_concept_record(tab)
    if %w[tab_synonymy tab_synonymy_for_profile_v2 tab_unpublished_citation tab_unpublished_citation_for_profile_v2 tab_classification
          tab_copy_to_new_reference tab_batch_loader_2].include?(tab) && @tabs_to_offer.include?(tab)
      tab
    else
      "tab_empty"
    end
  end

  def tab_for_citing_instance_in_name_search(tab)
    if %w[tab_synonymy tab_synonymy_for_profile_v2 tab_create_unpublished_citation tab_unpublished_citation_for_profile_v2].include?(tab)
      tab
    elsif %w[tab_copy_to_new_reference tab_copy_to_new_profile_v2].include?(tab)
      "tab_copy_to_new_reference_na"
    else
      "tab_empty"
    end
  end
end
