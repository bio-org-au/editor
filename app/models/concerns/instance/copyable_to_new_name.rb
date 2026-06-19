# frozen_string_literal: true

module Instance::CopyableToNewName
  extend ActiveSupport::Concern

  def copy_to_new_name(new_name_id, as_username)
    raise "Copied record would have same name id." if new_name_id.eql?(name_id)

    new = dup
    new.name_id = new_name_id
    new.created_by = new.updated_by = as_username
    new.source_system = new.source_id = new.source_id_string = nil
    new.uri = nil
    new.lock_version = 0
    new.save!
    new
  end

  def citation_for_standalone
    "#{reference.citation_html}".html_safe +
    (page.present? ? ": #{page}" : "") +
    (instance_type.try('primary_instance') ? "[#{instance_type.name}]" : "")
  end

  def instance_id_to_copy
    id
  end
end
