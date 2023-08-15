# frozen_string_literal: true

# Reference Duplicate Of typeahead params are resolvable.
module ReferenceParentResolvable
  extend ActiveSupport::Concern

  def resolve_parent(params)
    field_name = "parent"
    key_field = "#{field_name}_id"
    ta_field = "#{field_name}_typeahead"
    return unless params.key?(key_field)

    send("#{key_field}=", Reference::AsResolvedTypeahead::ForParent.new(
      params[key_field],
      params[ta_field],
      field_name.capitalize
    ).value)
  end
end
