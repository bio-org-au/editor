# frozen_string_literal: true

# Name Parent resolvable typeahead parameters
module NameParentResolvable
  extend ActiveSupport::Concern

  def resolve_parent(params, field_name_stub)
    key_field = "#{field_name_stub}_id"
    ta_field = "#{field_name_stub}_typeahead"
    return unless params.key?(key_field)

    send("#{key_field}=", Name::AsResolvedTypeahead::ForParent.new(
      params[key_field],
      params[ta_field],
      field_name_stub.capitalize
    ).value)
  end
end
