# == Schema Information
#
# Table name: product_context(The sets of products that a user can validly set a context for in the editor)
#
#  id(The identifier for a product context record.)                                                                                                                                                              :bigint           not null, primary key
#  api_date(The date when a system user, script, jira or services task last changed this record.)                                                                                                                :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.)                                                                                                            :string(50)
#  created_by(The user id of the person who created this data)                                                                                                                                                   :string(50)       not null
#  description(A description for this context)                                                                                                                                                                   :text             default("Please describe this product context"), not null
#  lock_version(A system field to manage row level locking.)                                                                                                                                                     :bigint           default(0), not null
#  name(The abbreviated name for a context. i.e. APNI/APC, APNI, APC, FoA)                                                                                                                                       :text             default("Name of the context"), not null
#  updated_by(The user id of the person who last updated this data)                                                                                                                                              :string(50)       not null
#  created_at(The date and time this data was created.)                                                                                                                                                          :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                                                                                                                                          :timestamptz      not null
#  context_id(A number that represents an available context. Only the name index and default accepted tree can share a context in each dataset ie. in vascular plants - APNI and APC can be in the same context) :bigint           not null
#  product_id(The product for a context)                                                                                                                                                                         :bigint           not null
#
# Indexes
#
#  pc_u_product_context  (context_id,product_id) UNIQUE
#
# Foreign Keys
#
#  pc_product_fk  (product_id => product.id)
#
class ProductContext < ApplicationRecord
  self.table_name = "product_context"
  self.primary_key = "id"

  belongs_to :product, class_name: "Product", foreign_key: "product_id"

end
