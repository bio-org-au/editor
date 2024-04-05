module Loader::Name::Doubt
  extend ActiveSupport::Concern
  
  # We take special care with doubtfulness.
  # The doubtful boolean column comes from the era of parsed data
  # and we need to keep it for those batches, but
  # the synonym type (which applies to synonyms and misapplieds) overrides
  # the doubtful flag once the synonym type is set.
  #
  # This method may need to be adjusted to clarify rules in future.
  def doubtful?
    if synonym_type.present? 
      return true if  self.synonym_type.match(/doubtful/)
    else
      return true if self.doubtful == true
    end

    false
  end
end

