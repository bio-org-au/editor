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
# Loader NameReviewCommentType entity
class Loader::Name::Review::Comment::Type < ActiveRecord::Base
  strip_attributes
  self.table_name = "name_review_comment_type"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  has_many :name_review_comments, class_name: "Loader::Name::Review::Comment",
             foreign_key: "name_review_comment_type_id"
  alias_attribute :comments, :name_review_comment_types

  attr_accessor :give_me_focus, :message

  def self.for(focus, compiler)
    self.where("not deprecated")
  end
end
  
