module Loader::Name::SortKey
  extend ActiveSupport::Concern

  def consider_sort_key
    if loader_batch.use_sort_key_for_ordering
      set_sort_key_if_blank
    else
      self.sort_key = nil
    end
  end

  # If a user sets a sort key we want to respect that
  # so don't over-write it
  # Conversely, if a user wants a sort_key reset they can simply
  # blank it out and hit save.
  def set_sort_key_if_blank
    normalise_sort_key unless sort_key.blank?
    if sort_key.blank?
      case record_type
      when "accepted"
        self.sort_key = "#{family.downcase}.family.#{record_type}.#{simple_name.downcase} #{' agenus' if rank == 'genus'}"
      when "excluded"
        self.sort_key = "#{family.downcase}.family.#{record_type}.#{simple_name.downcase} #{' agenus' if rank == 'genus'}"
      when "synonym"
        self.sort_key = synonym_sort_key(parent.sort_key)
      when "misapplied"
        self.sort_key = misapp_sort_key(parent.sort_key)
      when "heading"
        self.sort_key = if rank.blank? || rank.downcase == "family"
                          "#{family.downcase}.family"
                        else
                          "aaa-rank-#{rank}-heading"
                        end
      when "in-batch-note"
        self.sort_key = in_batch_note_sort_key if sort_key.blank?
      when "in-batch-compiler-note"
        self.sort_key = in_batch_compiler_note_sort_key if sort_key.blank?
      else
        self.sort_key = "aaaaaa-unexpected-record-type-#{record_type}"
      end
    end
  rescue StandardError => e
    puts e
    puts "set_sort_key: record_type: #{record_type}; rank: #{rank}; family: #{family}"
    raise
  end

  # This is for when we are combining our sort_key algorithm with a synonym sort 
  # value from taxon_mv(_new) - we want enough of a sort_key for the synonym
  # to place it under its parent, but not enough to determine its sorting
  # position within other synonyms for that parent.
  def set_short_sort_key
    normalise_sort_key unless sort_key.blank?
    if sort_key.blank? && record_type == 'synonym'
      self.sort_key = synonym_short_sort_key(parent.sort_key)
    end
  rescue StandardError => e
    puts e
    puts "set_short_sort_key: record_type: #{record_type}; rank: #{rank}; family: #{family}"
    raise
  end

  def normalise_sort_key
    self.sort_key = sort_key.downcase unless sort_key == sort_key.downcase
  end

  def synonym_sort_key(parent_sort_key, syn_type = synonym_type)
    "#{parent_sort_key}.a-syn.#{synonym_sort_key_tail(syn_type)}"
  end

  # This is designed to leave detailed syn ordering to a key from taxon_mv
  def synonym_short_sort_key(parent_sort_key, syn_type = synonym_type)
    "#{parent_sort_key}.a-syn."
  end

  def misapp_sort_key(parent_sort_key)
    "#{parent_sort_key}.b-mis.z-mis"
  end

  def synonym_sort_key_tail(syn_type = synonym_type)
    case syn_type
    when "isonym"
      "a-isonym"
    when "orthographic variant"
      "b-orth-var"
    when "basionym"
      "c-basionym"
    when "replaced synonym"
      "d-replaced-syn"
    when "alternative name"
      "e-alt-name"
    when "nomenclatural synonym"
      "f-nom-syn"
    when "taxonomic synonym"
      "g-tax-syn"
    when "doubtful pro parte taxonomic synonym"
      "g-tax-syn"
    when "doubtful-taxonomic-synonym"
      "g-tax-syn"
    when "pro parte taxonomic synonym"
      "g-tax-syn"
    else
      "x-is-unknown-#{syn_type}"
    end
  end
end
