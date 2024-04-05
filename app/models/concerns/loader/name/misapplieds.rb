module Loader::Name::Misapplieds
  extend ActiveSupport::Concern

  # synonym_type takes precedence
  def partial_misapplied?
    unless synonym_type.blank? 
      synonym_type&.match?(/pro parte/)
    else
      publ_partly&.match(/p\.p\./)
    end
  end
end
