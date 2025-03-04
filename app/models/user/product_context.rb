# == Schema Information
#
# Table name: user_product_context(A context that a user can validly set in the editor)
#
#  api_date(The date when a system user, script, jira or services task last changed this record.)     :timestamptz
#  api_name(The name of a system user, script, jira or services task which last changed this record.) :string(50)
#  created_by(The user id of the person who created this data)                                        :string(50)       not null
#  is_default(The default context for a user when they logon)                                         :boolean          default(FALSE), not null
#  lock_version(A system field to manage row level locking.)                                          :bigint           default(0), not null
#  updated_by(The user id of the person who last updated this data)                                   :string(50)       not null
#  created_at(The date and time this data was created.)                                               :timestamptz      not null
#  updated_at(The date and time this data was updated.)                                               :timestamptz      not null
#  context_id(Context given to a user)                                                                :bigint           not null, primary key
#  user_id(User given the context)                                                                    :bigint           not null, primary key
#
# Indexes
#
#  upc_user_context  (user_id,context_id) UNIQUE
#
# Foreign Keys
#
#  ucr_users_fk  (user_id => users.id)
#
# A context that a user can validly set in the editor
class User::ProductContext < ApplicationRecord
  self.table_name = "user_product_context"

  belongs_to :user, foreign_key: "user_id"

  scope :default, -> { where(is_default: true) }

  validates :context_id, :created_by, :updated_by, presence: true

  def products
    Product.where(id: Product::Context.where(context_id: context_id).pluck(:product_id))
  end
end
