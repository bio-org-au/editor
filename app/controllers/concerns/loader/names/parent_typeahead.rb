module Loader::Names::ParentTypeahead
  def work_out_parent_from_typeahead
    if params[:loader_name][:parent_typeahead].blank?
      params[:loader_name][:parent_id] = nil
    else 
      check_for_mismatched_parent_typeahead 
    end
  end  

  # They've selected one from typeahead
  def matched_parent_typeahead_and_id?
    return embedded_parent_typeahead_id(params[:loader_name][:parent_typeahead]) == params[:loader_name][:parent_id]
  end

  def check_for_mismatched_parent_typeahead
    return if matched_parent_typeahead_and_id?

    possible_names = Loader::Name.where(simple_name: params[:loader_name][:parent_typeahead])
                                 .where(loader_batch_id: @loader_name.loader_batch_id)
    if possible_names.blank?
      raise "Parent Name supplied doesn't match any names in this record's batch"
    elsif possible_names.size == 1
      params[:loader_name][:parent_id] = possible_names.first.id
    elsif possible_names.size > 1
      if possible_names.map(&:id).include?(params[:loader_name][:parent_id].to_i)
        # do nothing, assume no change
      else
        raise "String matches too many names in this record's batch"
      end
    end
  end
end
