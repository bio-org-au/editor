require "open-uri"

# Suspect this is never called.  GC July 2023
module TreeVersionElements
  class DiffHtml
    def initialize(previous_tve, current_tve)
      throw "Contact app developer if you see this message (1)"
      @previous_tve = previous_tve
      @current_tve = current_tve
    end

    def get
      throw "Contact app developer if you see this message (2)"
      url = "#{Rails.configuration.try('services_clientside_root_url')}tree-version/diff-element?e1=#{CGI.escape(@previous_tve)}&e2=#{CGI.escape(@current_tve)}&embed=true"
      Rails.logger.debug("@previous_tve: #{@previous_tve}")
      Rails.logger.debug("@current_tve: #{@current_tve}")
      Rails.logger.debug("TreeVersionElements#DiffHtml get url: #{url}")
      RestClient.get(url, "Accept" => "text/html") { |f| f.read }
    end

    # split the diff to get just the after part
    def after_html
      throw "Contact app developer if you see this message (3)"
      after = get
      return "nothing found" if after.blank?

      after.sub!(/.*<div class="diffAfter">/m, '<div class="diffAfter">')
    end

    # split the diff to get just the before part
    def before_html
      throw "Contact app developer if you see this message (4)"
      before = get
      return "nothing found" if before.blank?

      before.sub!(/<div class="diffAfter">.*/m, "")
      before
    end
  end
end
