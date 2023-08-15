# frozen_string_literal: true

# Author Author resolvable typeahead parameters
module AuthorAuthorResolvable
  extend ActiveSupport::Concern

  def resolve_author(params, param_stub, author)
    key_field = "#{param_stub}_id"
    ta_field = "#{param_stub}_typeahead"
    return unless params.key?(key_field)

    send("#{key_field}=", Author::AsResolvedTypeahead::ForDuplicateOf.new(
      params[key_field],
      params[ta_field],
      author
    ).value)
  end
end
