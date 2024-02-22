module Loader::Name::InBatchCompilerNote
  extend ActiveSupport::Concern

  NA = "N/A"
  def in_batch_compiler_note?
    record_type == "in-batch-compiler-note"
  end

  def set_in_batch_compiler_note_defaults
    return unless record_type == "in-batch-compiler-note"

    self.simple_name_as_loaded = NA
    self.family = NA if family.blank?
    self.simple_name = NA if simple_name.blank?
    self.full_name = simple_name
  end
  
  def in_batch_compiler_note_sort_key
    if family == NA && simple_name == NA
      "aaaa-in-batch-compiler-note"
    elsif simple_name == NA
      "#{family.downcase}.family.a.in-batch-compiler-note"
    else
      "#{family.downcase}.family.accepted.#{simple_name.downcase}.x.in-batch-compiler-note"
    end
  end
end
