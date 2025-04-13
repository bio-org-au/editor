# Name model
# == Schema Information
#
# Table name: name
#
#  id                    :bigint           not null, primary key
#  apni_json             :jsonb
#  changed_combination   :boolean          default(FALSE), not null
#  created_by            :string(50)       not null
#  full_name             :string(512)
#  full_name_html        :string(2048)
#  lock_version          :bigint           default(0), not null
#  name_element          :string(255)
#  name_path             :text             default(""), not null
#  orth_var              :boolean          default(FALSE), not null
#  published_year        :integer
#  simple_name           :string(250)
#  simple_name_html      :string(2048)
#  sort_name             :string(250)
#  source_id_string      :string(100)
#  source_system         :string(50)
#  status_summary        :string(50)
#  updated_by            :string(50)       not null
#  uri                   :text
#  valid_record          :boolean          default(FALSE), not null
#  verbatim_rank         :string(50)
#  created_at            :timestamptz      not null
#  updated_at            :timestamptz      not null
#  author_id             :bigint
#  base_author_id        :bigint
#  basionym_id           :bigint
#  duplicate_of_id       :bigint
#  ex_author_id          :bigint
#  ex_base_author_id     :bigint
#  family_id             :bigint
#  name_rank_id          :bigint           not null
#  name_status_id        :bigint           not null
#  name_type_id          :bigint           not null
#  namespace_id          :bigint           not null
#  parent_id             :bigint
#  primary_instance_id   :bigint
#  sanctioning_author_id :bigint
#  second_parent_id      :bigint
#  source_dup_of_id      :bigint
#  source_id             :bigint
#
# Indexes
#
#  lower_full_name                          (lower((full_name)::text))
#  name_author_index                        (author_id)
#  name_baseauthor_index                    (base_author_id)
#  name_duplicate_of_id_index               (duplicate_of_id)
#  name_exauthor_index                      (ex_author_id)
#  name_exbaseauthor_index                  (ex_base_author_id)
#  name_full_name_index                     (full_name)
#  name_full_name_trgm_index                (full_name) USING gin
#  name_lower_f_unaccent_full_name_like     (lower(f_unaccent((full_name)::text)) varchar_pattern_ops)
#  name_lower_full_name_gin_trgm            (lower((full_name)::text) gin_trgm_ops) USING gin
#  name_lower_simple_name_gin_trgm          (lower((simple_name)::text) gin_trgm_ops) USING gin
#  name_lower_unacent_full_name_gin_trgm    (lower(f_unaccent((full_name)::text)) gin_trgm_ops) USING gin
#  name_lower_unacent_simple_name_gin_trgm  (lower(f_unaccent((simple_name)::text)) gin_trgm_ops) USING gin
#  name_name_element_index                  (name_element)
#  name_name_path_index                     (name_path) USING gin
#  name_parent_id_ndx                       (parent_id)
#  name_rank_index                          (name_rank_id)
#  name_sanctioningauthor_index             (sanctioning_author_id)
#  name_second_parent_id_ndx                (second_parent_id)
#  name_simple_name_index                   (simple_name)
#  name_sort_name_idx                       (sort_name)
#  name_source_index                        (namespace_id,source_id,source_system)
#  name_source_string_index                 (source_id_string)
#  name_status_index                        (name_status_id)
#  name_system_index                        (source_system)
#  name_type_index                          (name_type_id)
#  uk_66rbixlxv32riosi9ob62m8h5             (uri) UNIQUE
#
# Foreign Keys
#
#  fk_156ncmx4599jcsmhh5k267cjv   (namespace_id => namespace.id)
#  fk_3pqdqa03w5c6h4yyrrvfuagos   (duplicate_of_id => name.id)
#  fk_5fpm5u0ukiml9nvmq14bd7u51   (name_status_id => name_status.id)
#  fk_5gp2lfblqq94c4ud3340iml0l   (second_parent_id => name.id)
#  fk_ai81l07vh2yhmthr3582igo47   (sanctioning_author_id => author.id)
#  fk_airfjupm6ohehj1lj82yqkwdx   (author_id => author.id)
#  fk_bcef76k0ijrcquyoc0yxehxfp   (name_type_id => name_type.id)
#  fk_coqxx3ewgiecsh3t78yc70b35   (base_author_id => author.id)
#  fk_dd33etb69v5w5iah1eeisy7yt   (parent_id => name.id)
#  fk_rp659tjcxokf26j8551k6an2y   (ex_base_author_id => author.id)
#  fk_sgvxmyj7r9g4wy9c4hd1yn4nu   (ex_author_id => author.id)
#  fk_sk2iikq8wla58jeypkw6h74hc   (name_rank_id => name_rank.id)
#  fk_whce6pgnqjtxgt67xy2lfo34    (family_id => name.id)
#  name_basionym_id_fkey          (basionym_id => name.id)
#  name_primary_instance_id_fkey  (primary_instance_id => instance.id)
#
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
  before_update :set_name_element_if_blank
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
    self.name_element = '[unknown]' if name_element.blank?
  end

  def set_name_element_if_blank
    self.name_element = '[unknown]' if name_element.blank?
  end
end
