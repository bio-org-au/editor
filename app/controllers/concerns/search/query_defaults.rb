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
    return false if value_already_applied? || value_not_needed?

    true
  end

  def value_already_applied?
    id_regex = /batch-id:/
    name_regex = /batch-name:/
    any_batch_regex = /any-batch:/
    default_name_regex = /default-batch: #{session[:default_loader_batch_name]}/i
    params[:query_string] =~ id_regex ||
      params[:query_string] =~ name_regex ||
      params[:query_string] =~ default_name_regex ||
      params[:query_string] =~ any_batch_regex
  end

  # gsub on dashes needed because they count as word-boundaries,
  # hence 'family-id:' was matching /\bid:/
  # had to stop that
  def value_not_needed?
    id_regex = /\bid:/
    id_with_syn_regex = /\bid-with-syn:/
    params[:query_string].gsub(/-/,'') =~ id_regex ||
      params[:query_string] =~ id_with_syn_regex
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
    #match_data = /(default-batch:\s[^:]{1,500})\s{1,500}\w{1,500}:/.match(params[:query_string])
    regex = Regexp.new(/(default-batch:\s[^:]{1,500})\s{1,500}\w{1,500}:/, timeout: 2.0)
    match_data = regex.match(params[:query_string])
    return if match_data.nil?

    reg = /#{match_data[1]}/
    params[:query_string].gsub!(reg, "")
  end

  def remove_old_default_at_end_of_string
    regex = Regexp.new(/(default-batch:\s[^:]{1,500})\s*$/, timeout: 2.0)
    match_data = regex.match(params[:query_string])
    return if match_data.nil?

    reg = /#{match_data[1]}/
    params[:query_string].gsub!(reg, "")
  end
end
