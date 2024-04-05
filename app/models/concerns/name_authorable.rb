# frozen_string_literal: true

# Name author associations and methods
# covering the various types of authors a name may have
module NameAuthorable
  extend ActiveSupport::Concern
  included do
    BASE = "base"
    EX = "ex"
    EX_BASE = "ex_base"
    SANCTIONING = "sanctioning"
    belongs_to :author, optional: true
    belongs_to :ex_author, class_name: "Author", optional: true
    belongs_to :base_author, class_name: "Author", optional: true
    belongs_to :ex_base_author, class_name: "Author", optional: true
    belongs_to :sanctioning_author, class_name: "Author", optional: true
  end

  def takes_authors?
    category_for_edit.takes_authors?
  end

  def takes_ex_base_author?
    takes_this_type_of_author?(EX_BASE)
  end

  def takes_base_author?
    takes_this_type_of_author?(BASE)
  end

  def takes_ex_author?
    takes_this_type_of_author?(EX)
  end

  def takes_sanctioning_author?
    takes_this_type_of_author?(SANCTIONING)
  end

  # Checks general configuration
  # and name category configuration
  # for a set of author types.
  def takes_this_type_of_author?(type_of_author)
    throw "Unknown type of author" unless [EX, BASE, EX_BASE, SANCTIONING].include?(type_of_author)
    return false unless category_for_edit.takes_authors?
    return false unless author_type_allowed_in_config(type_of_author)

    true
  end

  # General config defaults to true if nothing is configured for that
  # type of author.
  # This means you need to configure the general config options to false
  # if you don't want these author fields.
  def author_type_allowed_in_config(type_of_author)
    target = "allow_name_#{type_of_author}_author"
    allowed = Rails.configuration.try(target)
    # Default to true if no config
    allowed = true if allowed.nil?
    allowed
  end

  def takes_author?
    takes_authors? || takes_author_only?
  end

  def takes_author_only?
    category_for_edit.takes_author_only == true
  end

  def author_and_ex_author_must_differ
    return unless author_id.present? && ex_author_id.present? && author_id == ex_author_id

    errors.add(:base, "The ex-author cannot be the same as the author.")
  end

  def base_author_and_ex_base_author_must_differ
    return unless base_author_id.present? &&
                  ex_base_author_id.present? &&
                  base_author_id == ex_base_author_id

    errors.add(:base, "The ex-base author cannot be the same as the base author.")
  end

  # I wish authorship was a column in the name table, but it isn't
  def authorship_extracted
    doc = Nokogiri::HTML(full_name_html)
    doc.search('authors').text
  end
end
