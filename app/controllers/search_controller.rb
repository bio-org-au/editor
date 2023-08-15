class SearchController < ApplicationController
  include Search::QueryDefaults
  before_action :hide_details

  def search
    handle_old
    run_local_search || run_empty_search
    respond_to do |format|
      format.html
      format.csv do
        data = @search.executed_query.results.to_csv
        send_data(encode_data_for_csv(data))
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    params[:error_message] = "That query did not work. Please check the \
    search directives and arguments."
    logger.error("Search error: #{e}")
    @search = Search::Error.new(params) unless @search.present?
  rescue StandardError => e
    params[:error_message] = e.to_s
    run_empty_search_to_show_error(params)
  end

  def set_include_common_and_cultivar
    session[:include_common_and_cultivar] = \
      !session[:include_common_and_cultivar]
    @empty_search = true
  end

  def help
    logger.debug("help params: #{params.inspect}")
    if params[:help_id].match(/-for-dynamic-target-/)
      @dynamic_target = params[:help_id].sub(/.{0,500}-for-dynamic-target-/, "")
                                        .gsub(/-/, " ")
      params[:help_id].sub!(/-for-dynamic-target-.*/, "")
      logger.debug("@dynamic_target: #{@dynamic_target}")
    else
      @dynamic_target = nil
    end
    help_content_path = Search::Help::PageMappings.new(params, @view_mode)
    raise 'no help content path' if help_content_path.partial.blank?
    logger.debug("help_content_path: #{help_content_path}")
    render partial: help_content_path.partial
  rescue => e
    logger.error("SearchController#help error displaying #{help_content_path}")
    logger.error(e.to_s)
    logger.error(params.inspect)
  end

  def reports; end

  private

  def trim_session_searches
    session[:searches].shift if session[:searches].size > 2
  end

  def run_local_search
    return false unless params[:query_string].present?

    logger.debug("focus_id: #{params[:focus_id]}")
    @focus_id = params[:focus_id]
    params[:current_user] = current_user
    check_query_defaults
    params[:include_common_and_cultivar_session] = \
      session[:include_common_and_cultivar]
    apply_view_mode
    # Avoid "A copy of Search has been removed from the module tree but is still active" error
    # https://stackoverflow.com/questions/29636334/a-copy-of-xxx-has-been-removed-from-the-module-tree-but-is-still-active
    @search = ::Search::Base.new(params)
    if @search.parsed_request&.print
      render :printable, layout: "print"
    else
      render :search
    end
    true
  end

  def run_empty_search
    params["target"] = if @view_mode == ViewMode::REVIEW
                         Loader::Batch.user_reviewable(@current_user.username)&.first&.name
                       else
                         "Names"
                       end
    @empty_search = true
    @search = Search::Empty.new(params)
  end

  def run_empty_search_to_show_error(params)
    @empty_search = true
    @search = Search::Empty.new(params)
  end

  def set_tree_defaults
    params[:query_field] = "apc" if params[:query_field].blank?
    params[:query] = plantae_haeckel if params[:query].blank?
  end

  # TODO: where is this needed and why?
  def plantae_haeckel
    Name.find_by(full_name: "Plantae Haeckel").id
  end

  # NOTE: services needs to be changed to use the "new" params
  # before you can remove this code
  def handle_old
    handle_old_style_params
    handle_names_plus_instances_target
  end

  # translate services/search/link
  def handle_old_style_params
    return unless params[:query].present?
    raise "Cannot handle this query-field: #{params[:query_field]}" unless params[:query_field] == "name-instances"

    params[:query_target] = "name"
    params[:query_string] = params[:query].sub(/\z/, " show-instances:")
  end

  def handle_names_plus_instances_target
    return unless params[:query_target].present?
    return unless params[:query_target] =~ /Names plus instances/i

    params[:query_target] = "name"
    return if params[:query_string] =~ /show-instances:/

    params[:query_string] = params[:query_string].sub(/\z/, " show-instances:")
  end

  def apply_view_mode
    return unless
      ["loader names",
       "bulk processing logs",
       "bulk_processing_logs"].include?(params["query_target"].downcase)

    Rails.logger.info("apply_view_mode:    @view_mode: #{@view_mode}")
    if params[:query_target] == "Bulk processing logs"
      @view_mode = ViewMode::WIDE
    elsif @view_mode == ViewMode::REVIEW
      @view = ViewMode::REVIEW.to_s
    else
      @view = ViewMode::STANDARD.to_s
    end
    Rails.logger.info("apply_view_mode:    @view_mode: #{@view_mode}")
    Rails.logger.info("apply_view_mode:    @view: #{@view}")
  end

  def encode_data_for_csv(data)
    data = data.unicode_normalize(:nfc).encode("UTF-16LE")
    "\xFF\xFE".dup.force_encoding("UTF-16LE") + data
  rescue StandardError => e
    logger.error(e.to_s)
    logger.error("This CSV error in the SearchController does not")
    logger.error("prevent CSV data being created but it does indicate")
    logger.error("failure to encode the CSV as UTF-16LE")
  end
end
