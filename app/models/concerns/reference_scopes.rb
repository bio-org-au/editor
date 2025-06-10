# frozen_string_literal: true

# Reference scopes
module ReferenceScopes
  extend ActiveSupport::Concern
  included do
    # https://github.com/Casecommons/pg_search
    pg_search_scope :search_citation_text_for,
                    against: :citation,
                    ignoring: :accents,
                    using: {
                      tsearch: {
                        dictionary: "simple",
                        prefix: "true",
                      }
                    }

    # https://robots.thoughtbot.com/optimizing-full-text-search-with-postgres-
    # tsvector-columns-and-triggers
    pg_search_scope :search_citation_tsv_for,
                    against: :citation,
                    using: {
                      tsearch: {
                        tsvector_column: "tsv",
                        dictionary: "english",
                        prefix: "true",
                      }
                    }

    scope :lower_citation_equals,
          ->(string) { where("lower(citation) = lower(?) ", string.downcase) }
    scope :lower_citation_like,
          (lambda do |string|
            where("lower(citation) like lower(?) ",
                  string.tr("*", "%").downcase)
          end)
    scope :not_duplicate,
          -> { where("duplicate_of_id is null") }
    scope :is_duplicate,
          -> { where("duplicate_of_id is not null") }
  end
end
