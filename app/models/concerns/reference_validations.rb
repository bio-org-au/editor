# frozen_string_literal: true

# Reference validations
module ReferenceValidations
  extend ActiveSupport::Concern
  included do
    validates :published, inclusion: { in: [true, false] }
    validates_length_of :volume,
                        maximum: 50,
                        message: "cannot be longer than 50 characters"
    validates_length_of :edition,
                        maximum: 50,
                        message: "cannot be longer than 50 characters"
    validates_length_of :pages,
                        maximum: 255,
                        message: "cannot be longer than 255 characters"
    validates_presence_of :ref_type_id,
                          :author_id,
                          :ref_author_role_id,
                          message: "cannot be empty."
    # Title and display_title are mandatory columns, but many records have
    # simply a single space in these column. But a single space is not enough
    # to avoid the validates_presence_of test, so using this length test
    # instead.
    validates :display_title, :title,
              length: { minimum: 1 }
    validates :year,
              numericality: { only_integer: true,
                              greater_than_or_equal_to: 1000,
                              less_than_or_equal_to: ->(_reference) { Date.current.year } },
              allow_nil: true
    validates :iso_publication_date, exclusion: { in: [nil],
                                                  message: "is required",
                                                  if: :iso_publication_date_required? }
    validates_exclusion_of :parent_id,
                           in: ->(reference) { [reference.id] },
                           allow_blank: true,
                           message: "and child cannot be the same record"
    validates_exclusion_of :duplicate_of_id,
                           in: ->(reference) { [reference.id] },
                           allow_blank: true,
                           message: "and master cannot be the same record"
    validates :language_id, presence: true
    validate :validate_parent
    validate :validate_fields_for_part
    validate :validate_uniqueness
    validate :validate_iso_publication_date
    validates_length_of :issn,
                        maximum: 16,
                        message: "cannot be longer than 16 characters"
    validates_length_of :isbn,
                        maximum: 16,
                        message: "cannot be longer than 16 characters"
  end

  def validate_uniqueness
    return if Reference.where(["coalesce(lower(title),'no title') = coalesce(lower(?),'no title')", title])
                       .where(ref_type_id: ref_type_id)
                       .where(["coalesce(parent_id,0) = coalesce(?,0)", parent_id])
                       .where(published: published)
                       .where(author_id: author_id)
                       .where(ref_author_role_id: ref_author_role_id)
                       .where(["coalesce(edition,'no edition data') = coalesce(?,'no edition data')", edition])
                       .where(["coalesce(volume,'no volume data') = coalesce(?,'no volume data')", volume])
                       .where(["coalesce(pages,'no pages data') = coalesce(?,'no pages data')", pages])
                       .where(["coalesce(iso_publication_date,'0') = coalesce(?,'0')", iso_publication_date])
                       .where([
                                "coalesce(publication_date,'no publication date data') = coalesce(?,'no publication date data')", publication_date
                              ])
                       .where(["coalesce(notes,'no notes data') = coalesce(?,'no notes data')", notes])
                       .where.not(id: id)
                       .where("duplicate_of_id is null")
                       .count == 0

    errors.add(:base, "Reference is not unique")
  end

  def validate_parent
    return if parent_id.blank?

    validate_non_blank_parent
  end

  def validate_non_blank_parent
    if ref_type.parent_allowed?
      validate_parent_allowed
    else
      errors.add(:parent_id, "is not allowed for a #{ref_type.name}")
    end
  end

  def validate_parent_allowed
    return if ref_type.parent.name == parent.ref_type.name

    errors.add(:parent_id, incompatible_parent_type_message)
  end

  def incompatible_parent_type_message
    "#{parent.ref_type.name.downcase} cannot contain
    a #{ref_type.name.downcase}. Please change Type or Parent."
  end

  # Reference that is a "part" of a paper has restricted fields
  def validate_fields_for_part
    return unless ref_type.part?

    a_part_ref_cannot_have_publication_details
    a_part_ref_cannot_have_publication_details_date
  end

  def a_part_ref_cannot_have_publication_details
    errors.add(:volume, "is not allowed for a Part") if volume.present?
    errors.add(:edition, "is not allowed for a Part") if edition.present?
  end

  def a_part_ref_cannot_have_publication_details_date
    errors.add(:iso_publication_date, "is not allowed for a Part") if iso_publication_date.present?
    return unless publication_date.present?

    errors.add(:publication_date,
               "is not allowed for a Part")
  end
end
