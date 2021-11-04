# frozen_string_literal: true


# Author validations
module AuthorValidations
  extend ActiveSupport::Concern
  included do
    validates :name,
              presence: { if: -> { abbrev.blank? },
                          unless: -> { duplicate_of_id.present? },
                          message: "can't be blank if abbrev is blank." }
    validates :abbrev,
              presence: { if: -> { name.blank? },
                          unless: -> { duplicate_of_id.present? },
                          message: "can't be blank if name is blank." }
    validates :abbrev,
              presence: { if: -> { names.size > 0 },
                          message: "can't be blank if names are attached." }
    validates :abbrev,
              presence: { if: -> { base_names.size > 0 },
                          message:
                          "can't be blank if base authored names attached." }
    validates :abbrev,
              presence: { if: -> { ex_base_names.size > 0 },
                          message:
                          "can't be blank if ex-base authored names attached." }
    validates :abbrev,
              presence: { if: -> { ex_names.size > 0 },
                          message:
                          "can't be blank if ex-authored names are attached." }
    validates :abbrev,
              presence: { if: -> { sanctioned_names.size > 0 },
                          message:
                          "can't be blank if sanctioned names are attached." }
    validates :abbrev,
              uniqueness: { unless: -> { abbrev.blank? },
                            case_sensitive: false,
                            message: "has already been used" }
    validates_exclusion_of :duplicate_of_id,
                           in: ->(author) { [author.id] },
                           allow_blank: true,
                           message: "and master cannot be the same record"
    validate :master_has_abbrev_if_needed, on: :update
  end

  def master_has_abbrev_if_needed
    return if abbrev.blank?
    return unless changed.include?('duplicate_of_id')
    return unless duplicate?
    return if duplicate_of.abbrev.present?
    errors.add(:base, "Cannot make this a duplicate of an author that has no abbreviation.")
  end
end
