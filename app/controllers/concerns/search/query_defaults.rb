module Search::QueryDefaults
  extend ActiveSupport::Concern

  def check_query_defaults
    apply_default_loader_batch if apply_default_loader_batch?
  end

  def apply_default_loader_batch?
    return false unless params[:query_target] =~ /loader.name/i

    if session[:default_loader_batch_name].nil?
      remove_old_defaults
      return false
    end
    return false if value_already_applied?
    true
  end

  def value_already_applied?
    id_regex = /batch-id:/
    name_regex = /batch-name:/
    default_name_regex = /default-batch: #{session[:default_loader_batch_name]}/i
    params[:query_string] =~ id_regex || 
      params[:query_string] =~ name_regex ||
      params[:query_string] =~ default_name_regex
  end

  def apply_default_loader_batch
    remove_old_defaults
    params[:query_string] = params[:query_string] + " default-batch: #{session[:default_loader_batch_name]}"
  end  

  def remove_old_defaults
    remove_old_default_embedded
    remove_old_default_at_end_of_string
  end

  def remove_old_default_embedded
    match_data = /(default-batch:\s[^:]+)\s+[\w]+:/.match(params[:query_string])
    return if match_data.nil?

    reg = /#{match_data[1]}/
    params[:query_string].gsub!(reg,'')
  end

  def remove_old_default_at_end_of_string
    match_data = /(default-batch:\s[^:]+)\s*$/.match(params[:query_string])
    return if match_data.nil?

    reg = /#{match_data[1]}/
    params[:query_string].gsub!(reg,'')
  end
end
