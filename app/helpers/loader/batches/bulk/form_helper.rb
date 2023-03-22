# frozen_string_literal: true


module Loader::Batches::Bulk::FormHelper
  def merge_family_search_directive(search_str) 
    search_str.sub(/bulk-ops:  *family:/, 'bulk-ops-family:')
  end 
end
