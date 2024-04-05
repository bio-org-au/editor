# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
class Instance::AsCopier < Instance
  def copy_with_new_name_id(new_name_id, as_username)
    raise "Copied record would have same name id." if new_name_id.eql?(name_id)

    new = dup
    new.name_id = new_name_id
    new.created_by = new.updated_by = as_username
    new.source_system = new.source_id = new.source_id_string = nil
    new.lock_version = 0
    new.save!
    new
  end

  def copy_with_citations_to_new_reference(params, as_username)
    new = nil
    raise "Need a reference" if params[:reference_id].blank?
    raise "Ref must be different" if params[:reference_id].to_i == reference.id
    raise "Unrecognized reference id" if params[:reference_id].to_i <= 0
    raise "No such ref" if Reference.find(params[:reference_id].to_i).blank?

    new_reference_id_string = params[:reference_id]
    new_page = params[:page]
    new_instance_type_id = params[:instance_type_id]
    new_is_draft = params[:draft]
    ActiveRecord::Base.transaction do
      new = dup
      new_reference_id = new_reference_id_string.to_i
      new.reference_id = new_reference_id
      new.instance_type_id = new_instance_type_id
      new.page = new_page
      new.draft = new_is_draft
      new.created_by = new.updated_by = as_username
      new.source_system = new.source_id = new.source_id_string = nil
      new.lock_version = 0
      new.uri = nil
      new.save!
      reverse_of_this_is_cited_by.each do |citer|
        new_citer = Instance.new
        new_citer.name_id = citer.name.id
        new_citer.reference_id = new_reference_id
        new_citer.cited_by_id = new.id
        new_citer.cites_id = citer.cites_id
        new_citer.instance_type_id = citer.instance_type_id
        new_citer.verbatim_name_string = citer.verbatim_name_string
        new_citer.bhl_url = citer.bhl_url
        new_citer.page = new_page
        new_citer.created_by = new_citer.updated_by = as_username
        new_citer.save!
      end
    end
    new
  end
end
