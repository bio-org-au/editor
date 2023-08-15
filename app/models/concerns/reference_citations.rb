# frozen_string_literal: true

# Reference Citations
module ReferenceCitations
  extend ActiveSupport::Concern
  included do
  end

  def set_citation!
    json = citation_json
    reload
    self.citation_html = json["result"]["citationHtml"]
    self.citation = json["result"]["citation"]
    save!
  end

  def citation_json
    resource = Reference::AsServices.citation_strings_url(id)
    JSON.load(RestClient.get(resource, "Accept" => "text/json"))
  rescue StandardError => e
    logger.error("Exception rescued in ReferencesController#citation_json!")
    logger.error(e.to_s)
    logger.error("Check resource: #{resource}")
    raise "After saving the record it was not possible to set the citation
    strings.  The service we need might not be running. If this continues
    please contact support."
  end
end
