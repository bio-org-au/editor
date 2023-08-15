# frozen_string_literal: true

# Name Duplicate Of resolvable typeahead parameters
module NameDuplicateOfResolvable
  extend ActiveSupport::Concern

  def resolve_duplicate_of(params)
    key_field = "duplicate_of_id"
    ta_field = "duplicate_of_typeahead"
    return unless params.key?(key_field)

    send("#{key_field}=", Name::AsResolvedTypeahead::ForDuplicateOf.new(
      params[key_field],
      params[ta_field]
    ).value)
  end
end
