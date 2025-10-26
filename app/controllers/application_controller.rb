class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_debug,
                :start_timer,
                :check_system_broadcast,
                :authenticate,
                :authorise,
                :set_view_mode,
                :set_session_default_loader_batch_name
  # around_action :user_tagged_logging
  # This is just an added comment to force-trigger the github workflow

  rescue_from ActionController::InvalidAuthenticityToken, with: :show_login_page
  rescue_from CanCan::AccessDenied do |ex|
    details = "#{ex.message} #{ex.action.to_sym} #{ex.subject.class.name}"
    logger.error("User #{@current_user.username} #{details}")

    @message = "Access Denied! Please contact the admin for proper permissions."
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("common-error-message-container", partial: "layouts/shared/message"), status: :forbidden
      end
      format.js { render "layouts/shared/message", status: :forbidden }
      format.html { head :forbidden }
    end
  end

  helper_method :current_user,
    :current_registered_user,
    :product_tab_service,
    :product_context_service,
    :current_context_id,
    :current_context_name,
    :current_product_from_context

  protected

  attr_reader :current_user, :current_registered_user

  def product_tab_service
    @product_tab_service ||= begin
      context_id = current_context_id
      if context_id
        Products::ProductTabService.for_context(context_id)
      else
        Products::ProductTabService.call(current_registered_user.available_products_from_roles)
      end
    end
  end

  def current_context_id
    session[:current_context_id]
  end

  def current_product_from_context
    return nil if current_context_id.nil?
    product_context_service.product_with_context(current_context_id)
  end

  def current_context_name
    return "Select Context" unless current_context_id

    session[:current_context_name] || "No Context Selected"
  end

  def product_context_service
    @product_context_service ||= Products::ProductContextService
      .call(products: current_registered_user.available_products_from_roles)
  end

  private

  def show_login_page
    logger.error("Invalid Authenticity Token.")
    if request.format == "text/javascript"
      logger.error('JavaScript request with invalid authenticity token\
                  - expired session?')
      render js: "alert('Your session may have expired. Please reload the whole page before continuing.');"
    else
      redirect_to start_sign_in_path, notice: "Please try again."
    end
  end

  def authorise
    controller = params[:controller]
    action = params[:tab].present? ? params[:tab] : params[:action]
    authorize!(controller, action)
  rescue CanCan::AccessDenied
    details = "is unauthorized for: #{controller} #{action}"
    logger.error("User #{@current_user.username} #{details}")
    raise
  end

  def authenticate
    if session[:username].blank?
      ask_user_to_sign_in
    else
      continue_user_session
    end
  end

  private

   # Add nested directories for partials
   def _prefixes
     @_prefixes_with_partials ||= super | %w(application/search_results
                  application/search_results/link_texts
                  )
   end

  # Edge case of deep linking to sign_in can happen after a login that failed due to no login group.
  def ask_user_to_sign_in
    session[:url_after_sign_in] = request.url unless request.url.to_s.match(/sign_in/)
    respond_to do |format|
      format.html { redirect_to start_sign_in_url, notice: "Please sign in." }
      format.json { render partial: "layouts/no_session.js" }
      format.js { js_render }
    end
  end

  def js_render
    if params[:help_id] =~ /search-examples/ || params[:help_id] =~ /search-help/
      logger.error("Handling unauth request for search-helpd or search-examples")
      render html: "<div class='embedded-notice'><b>Your session may have expired.  Please reload the whole page before continuing.</b></div><script>alert('login...';) </script>".html_safe
    elsif params[:tab].blank?
      logger.error("Handling unauth request for a non-tab")
      render js: "alert('Your session may have expired. Please reload the whole page before continuing.');",
             layout: true
    else
      logger.error("Handling unauth request for the rest, including tabs")
      render html: "<div class='embedded-notice'><b>Your session may have expired.  Please reload the whole page before continuing.</b></div><script>alert('login...';) </script>".html_safe
    end
  end

  def continue_user_session
    @current_user = SessionUser.new(username: session[:username],
                             full_name: session[:user_full_name],
                             groups: session[:groups])
    @current_registered_user = @current_user.registered_user

    if current_product_from_context
      @current_user.set_current_product_from_context(current_product_from_context)
    end

    logger.info("User is known: #{@current_user.username}")
    set_working_draft_session
  end

  def set_working_draft_session
    @working_draft = nil
    return unless session[:draft].present? && TreeVersion.exists?(session[:draft]["id"])

    version = TreeVersion.find(session[:draft]["id"])
    if version.published
      session[:draft] = nil
    else
      @working_draft = version
    end
  end

  def hide_details
    @no_search_result_details = true
  end

  def show_details
    @no_search_result_details = false
  end

  attr_reader :current_user

  def username
    @current_user.username
  rescue StandardError
    "no current user"
  end

  # Could not get this to work with a guard clause.
  def javascript_only
    return if request.format == "text/javascript" || request.format == "application/json"

    logger.error("Rejecting a non-JavaScript request (format: #{request.format}) Is Firebug console on?")
    false
  end

  def pick_a_tab(default_tab = "tab_show_1")
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             default_tab
           end
  end

  def pick_a_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end

  def empty_search
    params["target"] = Search::Target.new(@view_mode).target
    @search = Search::Empty.new(params)
    @empty_search = true
  end

  def non_empty_search
    # params["target"] = Search::Target.new(@view_mode).target
    # @search = Search::Empty.new(params)
    @empty_search = false
  end

  def set_debug
    @debug = false
  end

  def start_timer
    @start_time = Time.now
  end

  def check_system_broadcast
    @system_broadcast = ""
    file_path = Rails.configuration.try("path_to_broadcast_file") || ""
    if File.exist?(file_path)
      logger.debug("System broadcast file exists at #{file_path}")
      file = File.open(file_path, "r")
      @system_broadcast = file.readline unless file.eof?
    end
  rescue StandardError => e
    logger.error("Problem with system broadcast.")
    logger.error(e.to_s)
  end

  def user_tagged_logging(&block)
    logger.tagged(username || "Anonymous", &block)
  end

  def set_view_mode
    if session[:view_mode_set_by_user] == true
      @view_mode = session[:view_mode]
      return
    end

    @view_mode = session[:view_mode] = ViewMode::STANDARD
    return unless defined? @current_user

    return if @current_user.edit?

    return unless @current_user.reviewer?

    @view_mode = session[:view_mode] = ViewMode::REVIEW
  end

  def set_session_default_loader_batch_name
    return if session[:default_loader_batch_id].blank?
    return if Loader::Batch.where(id: session[:default_loader_batch_id])

    session[:default_loader_batch_name] =
      Loader::Batch.find(session[:default_loader_batch_id]).name
  end
end

class Hash
  def to_html_list
    s = '<ul>'
    self.sort.to_h.each do |key, value|

      if value.nil?
      #  s += "<li>#{key}</li>"
      elsif value.is_a?(Hash)
        s += "<li>#{key}<ul>"
        s += value.sort.to_h.to_html_list
        s += "</ul></li>"
      else
        s += "<li>#{key}: #{value}</li>"
      end
    end
    s += '</ul>'
    s
  end
end
