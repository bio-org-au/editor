# frozen_string_literal: true

# == Schema Information
#
# Table name: role
#
#  id           :bigint           not null, primary key
#  created_by   :string(50)       not null
#  description  :text             default("Please describe this product role type"), not null
#  lock_version :bigint           default(0), not null
#  name         :citext           not null
#  updated_by   :string(50)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#
# Indexes
#
#  prt_unique_name  (name) UNIQUE
#
class Role < ActiveRecord::Base
  strip_attributes
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  has_many :product_roles, class_name: "Product::Role"
  has_many :user_product_roles, class_name: "User::ProductRole", through: :product_roles
end
