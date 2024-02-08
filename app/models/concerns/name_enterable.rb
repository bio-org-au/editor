# frozen_string_literal: true

# Name fields that are offered for the various types and categories of names.
module NameEnterable
  extend ActiveSupport::Concern
  included do
  end

  def status_options
    NameStatus.options_for_category(category_for_edit)
  end

  def takes_name_element?
    category_for_edit.takes_name_element?
  end

  def takes_rank?
    category_for_edit.takes_rank?
  end

  def takes_verbatim_rank?
    category_for_edit.takes_verbatim_rank?
  end

  def requires_name_element?
    category_for_edit.requires_name_element?
  end

  def needs_top_buttons?
    category_for_edit.needs_top_buttons?
  end

  def requires_higher_ranked_parent?
    category_for_edit.requires_higher_ranked_parent?
  end

  def category_name_for_edit
    if change_category_name_to.present?
      change_category_name_to
    else
      name_type.name_category.name
    end
  end

  def category_for_edit
    NameCategory.find_by_name(category_name_for_edit)
  end

  # Default to false, so that this field
  # will not appear in shards with no config item
  # to minimize disruption of adding it
  def takes_changed_combination?
    config_name = "allow_name_changed_combination"
    allow = Rails.configuration.try(config_name)
    allow = false if allow.nil?
    allow
  end

  # Default to false, so that this field
  # will not appear in shards with no config item
  # to minimize disruption of adding it
  def takes_published_year?
    config_name = "allow_name_published_year"
    allow = Rails.configuration.try(config_name)
    allow = false if allow.nil?
    allow
  end
end
