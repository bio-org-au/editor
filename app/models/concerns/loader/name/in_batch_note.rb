module Loader::Name::InBatchNote
  extend ActiveSupport::Concern

  NA = "N/A"
  def in_batch_note?
    record_type == "in-batch-note"
  end

  def set_in_batch_note_defaults
    return unless record_type == "in-batch-note"

    self.simple_name_as_loaded = NA
    self.family = NA if family.blank?
    self.simple_name = NA if simple_name.blank?
    self.full_name = simple_name
  end
  
  def in_batch_note_sort_key
    if family == NA && simple_name == NA
      "aaaa-in-batch-note"
    elsif simple_name == NA
      "#{family.downcase}.family.a.in-batch-note"
    else
      "#{family.downcase}.family.accepted.#{simple_name.downcase}.x.in-batch-note"
    end
  end
end
