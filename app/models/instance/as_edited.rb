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
# == Schema Information
#
# Table name: instance
#
#  id                   :bigint           not null, primary key
#  bhl_url              :string(4000)
#  cached_synonymy_html :text
#  created_by           :string(50)       not null
#  draft                :boolean          default(FALSE), not null
#  lock_version         :bigint           default(0), not null
#  nomenclatural_status :string(50)
#  page                 :string(255)
#  page_qualifier       :string(255)
#  source_id_string     :string(100)
#  source_system        :string(50)
#  uncited              :boolean          default(FALSE), not null
#  updated_by           :string(1000)     not null
#  uri                  :text
#  valid_record         :boolean          default(FALSE), not null
#  verbatim_name_string :string(255)
#  created_at           :timestamptz      not null
#  updated_at           :timestamptz      not null
#  cited_by_id          :bigint
#  cites_id             :bigint
#  instance_type_id     :bigint           not null
#  name_id              :bigint           not null
#  namespace_id         :bigint           not null
#  parent_id            :bigint
#  reference_id         :bigint           not null
#  source_id            :bigint
#
# Indexes
#
#  instance_citedby_index        (cited_by_id)
#  instance_cites_index          (cites_id)
#  instance_instancetype_index   (instance_type_id)
#  instance_name_index           (name_id)
#  instance_parent_index         (parent_id)
#  instance_reference_index      (reference_id)
#  instance_source_index         (namespace_id,source_id,source_system)
#  instance_source_string_index  (source_id_string)
#  instance_system_index         (source_system)
#  no_duplicate_synonyms         (name_id,reference_id,instance_type_id,page,cites_id,cited_by_id) UNIQUE
#  uk_bl9pesvdo9b3mp2qdna1koqc7  (uri) UNIQUE
#
# Foreign Keys
#
#  fk_30enb6qoexhuk479t75apeuu5  (cites_id => instance.id)
#  fk_gdunt8xo68ct1vfec9c6x5889  (name_id => name.id)
#  fk_gtkjmbvk6uk34fbfpy910e7t6  (namespace_id => namespace.id)
#  fk_hb0xb97midopfgrm2k5fpe3p1  (parent_id => instance.id)
#  fk_lumlr5avj305pmc4hkjwaqk45  (reference_id => reference.id)
#  fk_o80rrtl8xwy4l3kqrt9qv0mnt  (instance_type_id => instance_type.id)
#  fk_pr2f6peqhnx9rjiwkr5jgc5be  (cited_by_id => instance.id)
#
class Instance::AsEdited < Instance
  def update_if_changed(params, username)
    logger.debug("Update if changed for params: #{params}")
    assign_attributes(clean_all(params))
    if changed?
      logger.debug("Instance has changes to: #{changed}")
      self.updated_by = username
      # We do this because the clean_all params below resets the attributes we've set
      self.concept_warning_bypassed = params[:concept_warning_bypassed] == "1"
      self.multiple_primary_override = params[:multiple_primary_override] == "1"
      self.duplicate_instance_override = params[:duplicate_instance_override] == "1"
      prevent_double_overrides
      save!
      "Updated"
    else
      "No change"
    end
  rescue StandardError => e
    logger.error("Instance::AsEdited with params: #{params}")
    logger.error("Instance::AsEdited with params: #{e}")
    raise
  end

  private

  def prevent_double_overrides
    return unless multiple_primary_override && duplicate_instance_override

    self.multiple_primary_override = self.duplicate_instance_override = false
  end
  private :prevent_double_overrides
  # Prevent empty or blank-filled params being treated as changes to empty
  # columns.
  def clean(param)
    if param == ""
      nil
    elsif param.nil?
      nil
    elsif param.rstrip == ""
      nil
    else
      param
    end
  end

  def clean_all(params)
    params.each do |key, value|
      params[key] = clean(value)
    end
  end
end
