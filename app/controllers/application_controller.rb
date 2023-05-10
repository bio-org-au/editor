class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_debug,
                :start_timer,
                :check_system_broadcast,
                :authenticate,
                :authorise,
                :set_view_mode
#  around_action :user_tagged_logging

  rescue_from ActionController::InvalidAuthenticityToken, with: :show_login_page
  rescue_from CanCan::AccessDenied do |_exception|
    logger.error("Access Denied")
    head :forbidden
  end

  protected

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

  def ask_user_to_sign_in
    session[:url_after_sign_in] = request.url
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
    @current_user = User.new(username: session[:username],
                             full_name: session[:user_full_name],
                             groups: session[:groups])
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
end
