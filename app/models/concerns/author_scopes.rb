# frozen_string_literal: true

# Author scopes
module AuthorScopes
  extend ActiveSupport::Concern
  included do
    # Only used for typeahead confirmation, so DO NOT use f_unaccent.
    scope :lower_name_equals,
          ->(string) { where("lower(name) = lower(?) ", string) }
    scope :lower_name_like,
          (lambda do |string|
            where("lower(f_unaccent(name)) like lower(f_unaccent(?)) ",
                  string.tr("*", "%"))
          end)
    scope :lower_abbrev_like,
          (lambda do |string|
            where("lower(f_unaccent(abbrev)) like lower(f_unaccent(?)) ",
                  string.tr("*", "%"))
          end)
    scope :not_this_id,
          ->(this_id) { where.not(id: this_id) }
    scope :not_duplicate,
          -> { where("author.duplicate_of_id is null") }
  end
end
