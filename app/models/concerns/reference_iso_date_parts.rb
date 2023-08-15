# frozen_string_literal: true

# Reference Iso Publication Date Components
module ReferenceIsoDateParts
  extend ActiveSupport::Concern
  included do
  end

  def day
    return nil if iso_publication_date.nil?
    return nil if iso_publication_date.length < 9

    iso_publication_date.scan(/..\z/).first
  end

  def day=(dd)
    return if dd == "0"
    return if dd == "00"
    return if dd == 0

    if dd.blank? # remove an existing day
      self.iso_publication_date = if month.nil?
                                    year
                                  else
                                    "#{year}-#{month}"
                                  end
    else # apply a non-blank day
      return if iso_publication_date.nil? # cannot add day because no year
      return if iso_publication_date.length < 7 # cannot add day because no month

      self.iso_publication_date = "#{iso_publication_date.match(/^....-../)}-#{dd.to_s.rjust(2, '0')}"
    end
  end

  def month
    return nil if iso_publication_date.nil?
    return nil if iso_publication_date.length < 7
    return iso_publication_date.scan(/..\z/).first if iso_publication_date.length == 7

    iso_publication_date.scan(/(?<=....-)..(?=-..)/).first
  end

  def month=(mm)
    if mm.blank?
      self.iso_publication_date = year
    elsif iso_publication_date.length == 4 || iso_publication_date.length == 7 # yyyy or yyyy-mm
      self.iso_publication_date = "#{year}-#{mm.to_s.rjust(2, '0')}"
    elsif iso_publication_date.length == 10 # yyyy-mm-dd
      self.iso_publication_date = "#{year}-#{mm.to_s.rjust(2, '0')}-#{day}"
    end
  end

  def year
    return nil if iso_publication_date.blank?
    return nil if iso_publication_date.nil?
    return nil if iso_publication_date.length < 4

    iso_publication_date.scan(/\A..../).first
  end

  def year=(yyyy)
    if iso_publication_date.nil? || iso_publication_date.length <= 4
      self.iso_publication_date = yyyy
    elsif iso_publication_date.length == 7
      self.iso_publication_date = "#{yyyy}-#{month}"
    elsif iso_publication_date.length == 10
      self.iso_publication_date = "#{yyyy}-#{month}-#{day}"
    end
  end
end
