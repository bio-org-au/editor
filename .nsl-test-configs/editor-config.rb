# frozen_string_literal: true

# Host
external_services_host = "http://localhost:9093/nsl/services"
internal_services_host = "http://localhost:9090/nsl/services"
# Environment
Rails.configuration.action_controller.relative_url_root = "/nsl/editor"
Rails.configuration.environment = "test"
Rails.configuration.draft_instances = "true"
Rails.configuration.profile_edit_aware = true
Rails.configuration.profile_v2_aware = true
Rails.configuration.unsaved_form_prompt_enabled = true
Rails.configuration.site_wide_form_prompt_enabled = true
Rails.configuration.multi_product_tabs_enabled = false
Rails.configuration.resource_tab_enabled = true
Rails.configuration.nsl_linker = "http://localhost:9090/"
# Services
Rails.configuration.services_clientside_root_url = "#{external_services_host}/"
Rails.configuration.services = "#{internal_services_host}/"
Rails.configuration.name_services = "#{internal_services_host}/rest/name/apni/"
Rails.configuration.reference_services = "#{internal_services_host}/rest/reference/apni/"
# - API key for the services
Rails.configuration.api_key = "test-api-key"
