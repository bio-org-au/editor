# frozen_string_literal: true

# Name validations
module NameValidatable
  extend ActiveSupport::Concern
  included do
    validates :second_parent_id, presence: true, if: :requires_parent_2?
    validates :name_rank_id, presence: true
    validates :name_type_id, presence: true
    validates :name_status_id, presence: true
    validates :ex_base_author,
              absence: { message: "cannot be set if there is no base author.",
                         if: -> { base_author_id.nil? } }
    validates :base_author,
              absence: { message: "cannot be set if there is no author.",
                         if: -> { author_id.nil? } }
    validates :ex_author,
              absence: { message: "cannot be set if there is no author.",
                         if: -> { author_id.nil? } }
    validates :name_element, presence: true, if: :requires_name_element?
    validate :name_element_is_stripped
    validates :parent_id, presence: true, if: :requires_parent? # tested
    validate :parent_rank_high_enough? # tested
    validate :name_type_must_match_category
    validate :author_and_ex_author_must_differ
    validate :base_author_and_ex_base_author_must_differ
    validates :created_by, presence: true
    validates :updated_by, presence: true
    validates_length_of :status_summary, maximum: 50
    validates_exclusion_of :duplicate_of_id,
                           in: ->(name) { [name.id] },
                           allow_blank: true,
                           message: "and master cannot be the same record"
    validates_exclusion_of :parent_id,
                           in: ->(name) { [name.id] },
                           allow_blank: true,
                           message: "cannot be the same record"
    validates_exclusion_of :second_parent_id,
                           in: ->(name) { [name.id] },
                           allow_blank: true,
                           message: "cannot be the same record"
    validates_exclusion_of :second_parent_id,
                           in: ->(name) { [name.parent_id] },
                           allow_blank: true,
                           message: "cannot be the same as the first parent",
                           unless: -> { cultivar_hybrid? }
    validates :second_parent_id, absence: true, unless: -> { requires_parent_2? }
    validates :verbatim_rank, length: { maximum: 50 }
    validates :published_year,
              numericality: { greater_than_or_equal_to: 1700,
                              less_than_or_equal_to: Date.current.year,
                              only_integer: true },
              allow_blank: true
    validates :uri, uniqueness: true, allow_blank: true
  end

  def name_element_is_stripped
    return unless name_element.present?
    return if name_element == name_element.strip

    errors.add(:name_element, "has whitespace")
  end
end
