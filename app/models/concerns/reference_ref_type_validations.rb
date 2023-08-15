# frozen_string_literal: true

# Reference Ref Type Validations
module ReferenceRefTypeValidations
  extend ActiveSupport::Concern
  included do
  end
  def ref_type_permits_parent?
    ref_type.parent_allowed?
  end

  def ref_type_message_about_parent
    if ref_type.blank?
      "Please choose a type."
    elsif ref_type_permits_parent?
      ref_type_cannot_have_parent_message
    else
      ref_type_cannot_have_parent_message
    end
  end

  def ref_type_can_have_parent_message
    parent_article = ref_type.parent.indefinite_article
    "#{ref_type.indefinite_article.capitalize} #{ref_type.name.downcase}
    type can have #{parent_article} #{ref_type.parent.name.downcase}
    type parent."
  end

  def ref_type_cannot_have_parent_message
    "#{ref_type.indefinite_article.capitalize} #{ref_type.name.downcase}
    type cannot have a parent."
  end
end
