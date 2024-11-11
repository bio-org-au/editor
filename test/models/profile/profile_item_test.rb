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
require "test_helper"

class Profile::ProfileItemTest < ActiveSupport::TestCase
  def setup
    @instance = instances(:gaertner_created_metrosideros_costata)
    @profile_item_type = profile_item_type(:ecology_pit)
    @profile_object_type = @profile_item_type.profile_object_type
    @profile_text = profile_text(:one_pt)
    @product_item_config = product_item_config(:ecology_pic)
    @profile_item = Profile::ProfileItem.create({
      instance_id: @instance.id,
      created_by: "tester",
      created_at: Time.now,
      updated_by: "tester",
      updated_at: Time.now,
      profile_text_id: @profile_text.id,
      product_item_config_id: @product_item_config.id
    })
  end

  test 'belongs to product item config' do
    assert_equal @product_item_config, @profile_item.product_item_config
  end

  test 'belongs to profile text' do
    assert_equal @profile_text, @profile_item.profile_text
  end

  test 'belongs to profile object type (optional)' do
    assert_nil @profile_item.profile_object_type

    @profile_item.update(profile_object_rdf_id: @profile_object_type.rdf_id)
    assert_equal @profile_object_type, @profile_item.profile_object_type
  end

  test 'has many profile item references' do
    reference1 = references(:paper_by_brassard)
    profile_item_reference1 = profile_item_reference(:one_pir)
    profile_item_reference1.update(profile_item: @profile_item, reference: reference1)

    reference2 = references(:section_with_brassard_author_same_as_parent)
    profile_item_reference2 = profile_item_reference(:two_pir)
    profile_item_reference2.update(profile_item: @profile_item, reference: reference2)

    profile_item_references = @profile_item.profile_item_references.map(&:profile_item_id_reference_id)
    assert_equal profile_item_references.include?(profile_item_reference1.profile_item_id_reference_id), true
    assert_equal profile_item_references.include?(profile_item_reference2.profile_item_id_reference_id), true
  end

  test 'has one product through product item config' do
    assert_equal @product_item_config.product, @profile_item.product
  end

  test 'has one profile item annotation' do
    annotation = profile_item_annotation(:one_pia)
    annotation.update(profile_item: @profile_item)
    assert_equal annotation.id, @profile_item.profile_item_annotation.id
  end
end