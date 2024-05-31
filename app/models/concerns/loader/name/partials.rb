module Loader::Name::Partials
  extend ActiveSupport::Concern

  # synonym_type takes precedence
  def partial_misapplied?
    unless synonym_type.blank? 
      synonym_type&.match?(/pro parte/)
    else
      publ_partly&.match(/p\.p\./)
    end
  end

  def partial_or_match_is_partial?
    synonym_type&.match?(/pro parte/) |
      preferred_match&.relationship_instance_type&.pro_parte?
  end
end
