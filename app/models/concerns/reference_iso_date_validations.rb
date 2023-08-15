# frozen_string_literal: true

# Reference validations
module ReferenceIsoDateValidations
  extend ActiveSupport::Concern

  def iso_publication_date_required?
    ref_type.reference_year_required?
  end

  def validate_iso_publication_date
    return if iso_publication_date.blank?

    validate_iso_string_length
    validate_iso_date_year unless iso_publication_date.blank?
    validate_iso_date_month unless iso_publication_date.length < 7
    validate_iso_day_month_year if iso_publication_date.length == 10
  rescue StandardError => e
    Rails.logger.error("Error in validate_iso_publication_date: #{e}")
    errors.add(:base, e.to_s)
  end

  def validate_iso_string_length
    return if iso_publication_date.blank?
    return if [0, 4, 7, 10].include? iso_publication_date.length

    raise "Publication date must be year, or year, month or year, month, day"
  end

  def validate_iso_date_year
    return if year.blank?
    raise "Year #{year} is in the future." if year.to_i > Date.today.year
    raise "Year #{year} is too far in the past." if year.to_i < 1000
  end

  def validate_iso_date_month
    return if month.blank?

    month_integer = month.to_i
    raise "Month #{month_integer} is above the range 1-12" if month_integer > 12
    raise "Month #{month_integer} is below the range 1-12" if month_integer < 1
  end

  def validate_iso_day_month_year
    return if Date.valid_date?(year.to_i, month.to_i, day.to_i)

    raise "Publication day, month, year combine to form \
      #{iso_publication_date}, which is an invalid date"
  end
end
