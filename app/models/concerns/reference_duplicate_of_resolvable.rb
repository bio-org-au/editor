# frozen_string_literal: true

# Reference Duplicate Of typeahead params are resolvable.
module ReferenceDuplicateOfResolvable
  extend ActiveSupport::Concern

  def resolve_duplicate_of(params)
    field_name = "duplicate_of"
    key_field = "#{field_name}_id"
    ta_field = "#{field_name}_typeahead"
    return unless params.key?(key_field)

    send("#{key_field}=", Reference::AsResolvedTypeahead::ForDuplicateOf.new(
      params[key_field],
      params[ta_field],
      field_name.capitalize
    ).value)
  end
end
