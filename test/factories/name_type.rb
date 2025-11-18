# == Schema Information
#
# Table name: name_type
#
#  id               :bigint           not null, primary key
#  autonym          :boolean          default(FALSE), not null
#  connector        :string(1)
#  cultivar         :boolean          default(FALSE), not null
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  formula          :boolean          default(FALSE), not null
#  hybrid           :boolean          default(FALSE), not null
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  scientific       :boolean          default(FALSE), not null
#  sort_order       :integer          default(0), not null
#  vernacular       :boolean          default(FALSE), not null
#  name_category_id :bigint           not null
#  name_group_id    :bigint           not null
#  rdf_id           :string(50)
#
# Indexes
#
#  name_type_rdfid  (rdf_id)
#  nt_unique_name   (name_group_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_10d0jlulq2woht49j5ccpeehu  (name_category_id => name_category.id)
#  fk_5r3o78sgdbxsf525hmm3t44gv  (name_group_id => name_group.id)
#
FactoryBot.define do
  factory :name_type do
    lock_version { 1 }
    sort_order { 1 }
    deprecated { false }

    # Default attributes - will be overridden by after(:build) callback
    autonym { false }
    cultivar { false }
    formula { false }
    hybrid { false }
    scientific { true }
    vernacular { false }

    association :name_group
    association :name_category

    # Use after(:build) to set appropriate values based on category or explicit name
    after(:build) do |name_type, evaluator|
      # Get the category name
      category_name = name_type.name_category&.name

      # If no name is set, determine it from category
      if name_type.name.blank?
        case category_name
        when "scientific"
          name_type.name = "scientific"
          name_type.scientific = true
          name_type.cultivar = false
          name_type.vernacular = false
        when "cultivar"
          name_type.name = "cultivar"
          name_type.scientific = false
          name_type.cultivar = true
          name_type.vernacular = false
        when "phrase name"
          name_type.name = "phrase name"
          name_type.scientific = false
          name_type.cultivar = false
          name_type.vernacular = true
        when "other"
          name_type.name = "[n/a]"
          name_type.scientific = false
          name_type.cultivar = false
          name_type.vernacular = false
        else
          # Default to scientific
          name_type.name = "scientific"
          name_type.scientific = true
          name_type.cultivar = false
          name_type.vernacular = false
        end
      else
        # Name was explicitly set, adjust flags accordingly
        case name_type.name
        when "cultivar"
          name_type.scientific = false
          name_type.cultivar = true
          name_type.vernacular = false
        when "phrase name"
          name_type.scientific = false
          name_type.cultivar = false
          name_type.vernacular = true
        when "[n/a]", "[unknown]", "[default]", "informal", "common"
          name_type.scientific = false
          name_type.cultivar = false
          name_type.vernacular = false
        when "scientific", "autonym", "sanctioned"
          name_type.scientific = true
          name_type.cultivar = false
          name_type.vernacular = false
        end
      end

      # Set rdf_id if not already set
      if name_type.rdf_id.blank?
        group_id_part = name_type.name_group_id.present? ? name_type.name_group_id : "unknown"
        name_type.rdf_id = "#{name_type.name.parameterize}-#{group_id_part}"
      end
    end


    # Trait for cultivar types
    trait :cultivar_type do
      name { "cultivar" }
      scientific { false }
      cultivar { true }
      vernacular { false }
      association :name_category, factory: :name_category, name: "cultivar"
    end

    # Trait for phrase name types
    trait :phrase_type do
      name { "phrase name" }
      scientific { false }
      cultivar { false }
      vernacular { true }
      association :name_category, factory: :name_category, name: "phrase name"
    end
  end
end
