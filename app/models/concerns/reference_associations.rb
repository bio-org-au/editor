# frozen_string_literal: true

# Reference Associations
module ReferenceAssociations
  extend ActiveSupport::Concern
  included do
    belongs_to :ref_type, foreign_key: "ref_type_id", optional: false
    belongs_to :ref_author_role, foreign_key: "ref_author_role_id", optional: false
    belongs_to :author, foreign_key: "author_id", optional: true

    # Prevent parent references being destroyed; cannot see how to enforce
    # this via acts_as_tree.
    belongs_to :parent, class_name: "Reference", foreign_key: "parent_id", optional: true
    has_many :children,
             class_name: "Reference",
             foreign_key: "parent_id",
             dependent: :restrict_with_exception

    # acts_as_tree foreign_key: :duplicate_of_id, order: "title"
    # Cannot have 2 acts_as_tree in one model.
    belongs_to :duplicate_of,
               class_name: "Reference",
               foreign_key: "duplicate_of_id",
               optional: true
    has_many :duplicates,
             class_name: "Reference",
             foreign_key: "duplicate_of_id",
             dependent: :restrict_with_exception

    belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id", optional: false
    belongs_to :language, optional: false

    has_many :profile_item_references, class_name: "Profile::ProfileItemReference", foreign_key: "reference_id", dependent: :destroy
    has_many :instances, foreign_key: "reference_id"
    has_many :name_instances,
             -> { where "cited_by_id is not null" },
             class_name: "Instance",
             foreign_key: "reference_id"
    has_many :novelties,
             (lambda do
               where "instance.instance_type_id in
               (select id from instance_type where primary_instance)"
             end),
             class_name: "Instance",
             foreign_key: "reference_id"
    has_many :comments
  end
end
