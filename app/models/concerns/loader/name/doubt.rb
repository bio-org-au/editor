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
      return true if self.synonym_type.match(/doubtful/)
    else
      return true if self.doubtful == true
    end

    false
  end

  # The method below is for use in the riti method.
  #
  # riti is used to determine the relationship instance type when 
  # creating a preferred match
  #
  # The above doubtful? method was being called in riti but was creating 
  # problems because it ignores the doubtful field when synonym type is present
  # - and synonym_type is usually present in parsed synonyms, but, as parsed, 
  # it ignores doubt # because doubt was recorded in a separate doubtful field.
  #
  def riti_doubtful?
    return true if self.synonym_type.match(/doubtful/)
    return true if self.doubtful == true

    false
  end
end

