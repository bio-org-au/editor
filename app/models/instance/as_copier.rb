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

  def copy_with_product_reference(params, as_username)
    new = nil
    raise "Need a reference" if params[:reference_id].blank?
    raise "Unrecognized reference id" if params[:reference_id].to_i <= 0
    raise "No such ref" if Reference.find_by(id: params[:reference_id].to_i).blank?

    new_reference_id_string = params[:reference_id]
    new_instance_type_id = params[:instance_type_id]
    new_is_draft = params[:draft]
    ActiveRecord::Base.transaction do
      new = dup
      new_reference_id = new_reference_id_string.to_i
      new.reference_id = new_reference_id
      new.instance_type_id = new_instance_type_id
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
        new_citer.created_by = new_citer.updated_by = as_username
        new_citer.save!
      end
    end
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
