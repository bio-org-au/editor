# Name model
class Name < ApplicationRecord
  self.table_name = "name"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  include NameScopable
  include AuditScopable
  include NameValidatable
  include NameParentable
  include NameFamilyable
  include NameNamePathable
  include NameTreeable
  include NameNamable
  include NameAuthorable
  include NameRankable
  include NameEnterable
  include Name::Loadable

  strip_attributes

  attr_accessor :display_as,
                :give_me_focus,
                :apc_instance_is_an_excluded_name,
                :apc_declared_bt,
                :change_category_name_to

  belongs_to :name_type, optional: false
  has_one :name_category, through: :name_type
  belongs_to :name_status, optional: false
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"

  belongs_to :duplicate_of, class_name: "Name", foreign_key: "duplicate_of_id", optional: true
  belongs_to :family, class_name: "Name", optional: true
  has_many   :members, class_name: "Name", foreign_key: "family_id"

  has_many :duplicates,
           class_name: "Name",
           foreign_key: "duplicate_of_id",
           dependent: :restrict_with_exception

  has_many :instances,
           foreign_key: "name_id",
           dependent: :restrict_with_error

  has_many :instance_types, through: :instances
  has_many :comments
  has_many :name_tag_names
  has_many :name_tags, through: :name_tag_names
  has_many :tree_nodes # not sure what this is, looks like a thought bubble
  has_many :tree_elements
  has_many :intended_tree_children,
           class_name: "Loader::Name::Match",
           foreign_key: "intended_tree_parent_name_id"

  SEARCH_LIMIT = 50
  DECLARED_BT = "DeclaredBt"

  before_create :set_defaults
  before_save :validate

  def primary_instances
    instances.where("instance_type_id in (select id from instance_type where primary_instance)")
  end

  def has_primary_instance?
    !primary_instances.empty?
  end

  def save_with_username(username)
    set_defaults # under rails 6 the before_create was not getting called (in time)
    self.created_by = self.updated_by = username
    save
  end

  def validate
    logger.debug("before save validate - errors: #{errors[:base].size}")
    errors[:base].size.zero?
  end

  def self.exclude_common_and_cultivar_if_requested(exclude)
    if exclude
      not_common_or_cultivar
    else
      where("1=1")
    end
  end

  def only_one_type?
    name_category.only_one_type?
  end

  def full_name_or_default
    full_name || "[this record has no full name]"
  end

  def display_as_part_of_concept
    self.display_as = :name_as_part_of_concept
  end

  def allow_delete?
    instances.blank? &&
      children.blank? &&
      comments.blank? &&
      duplicates.blank? &&
      !family_dependents?
  end

  def family_dependents?
    return false unless name_rank.family?

    # From here on, must be a family
    return false if family_members.empty? # 0 members
    return true if family_members.length > 1 # 2 or more members

    # From here on, only 1 family member
    return true if family_id.blank? # 1 but null so not itself
    return false if family_id = id # 1 but is itself
    return true if family_id != id # 1 but it is not itself

    true # fail safe - shouldn't get here
  end

  def migrated_from_apni?
    !source_system.blank?
  end

  def anchor_id
    "Name-#{id}"
  end

  def hybrid?
    name_type.hybrid?
  end

  def self.dummy_record
    find_by_name_element("Unknown")
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def cultivar_hybrid?
    name_category.cultivar_hybrid?
  end

  def names_in_path
    parents = []
    name = self
    while name.parent
      name = name.parent
      parents.push(name)
    end
    parents
  end

  def de_dupe
    dd = Name::DeDuper.new(self)
    dd.de_dupe
  end

  def de_dupe_preview
    dd = Name::DeDuper.new(self)
    dd.preview
  end

  def de_duper
    Name::DeDuper.new(self)
  end

  def has_dependents
    Name::HasDependents.new(self)
  end

  def transfer_dependents(dependent_type)
    dd = Name::DeDuper.new(self)
    dd.transfer_dependents(dependent_type)
  end

  def self.children_of_duplicates_count
    sql = "select count(*) total from name n join name parent on n.parent_id = parent.id where parent.duplicate_of_id is not null"
    records_array = ActiveRecord::Base.connection.execute(sql)
    records_array.first["total"]
  end

  def self.instances_of_duplicates_count
    sql = "select count(*) total from name join instance on name.id = instance.name_id where name.duplicate_of_id is not null"
    records_array = ActiveRecord::Base.connection.execute(sql)
    records_array.first["total"]
  end

  def self.family_members_of_duplicates_count
    sql = "select count(*) total from name join name family on name.family_id = family.id where family.duplicate_of_id is not null"
    records_array = ActiveRecord::Base.connection.execute(sql)
    records_array.first["total"]
  end

  def self.transfer_all_dependents(dependent_type)
    total = 0
    Name.where("duplicate_of_id is not null").each do |duplicate|
      dd = Name::DeDuper.new(duplicate)
      total += dd.transfer_dependents(dependent_type)
    end
    total
  end

  private

  def set_defaults
    self.namespace_id = Namespace.default.id if namespace_id.blank?
  end
end
