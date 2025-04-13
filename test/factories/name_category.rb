# == Schema Information
#
# Table name: name_category
#
#  id                            :bigint           not null, primary key
#  description_html              :text
#  lock_version                  :bigint           default(0), not null
#  max_parents_allowed           :integer          default(0), not null
#  min_parents_required          :integer          default(0), not null
#  name                          :string(50)       not null
#  parent_1_help_text            :text
#  parent_2_help_text            :text
#  requires_family               :boolean          default(FALSE), not null
#  requires_higher_ranked_parent :boolean          default(FALSE), not null
#  requires_name_element         :boolean          default(FALSE), not null
#  sort_order                    :integer          default(0), not null
#  takes_author_only             :boolean          default(FALSE), not null
#  takes_authors                 :boolean          default(FALSE), not null
#  takes_cultivar_scoped_parent  :boolean          default(FALSE), not null
#  takes_hybrid_scoped_parent    :boolean          default(FALSE), not null
#  takes_name_element            :boolean          default(FALSE), not null
#  takes_rank                    :boolean          default(FALSE), not null
#  takes_verbatim_rank           :boolean          default(FALSE), not null
#  rdf_id                        :string(50)
#
# Indexes
#
#  name_category_rdfid           (rdf_id)
#  uk_rxqxoenedjdjyd4x7c98s59io  (name) UNIQUE
#
FactoryBot.define do
  factory :name_category do
    sort_order { 1 }
    rdf_id { "Sample Rdf" }
    max_parents_allowed { 1 }
    min_parents_required { 1 }
    requires_family { true }
    requires_higher_ranked_parent { true }
    requires_name_element { true }
    takes_author_only { true }
    takes_authors { true }
    takes_cultivar_scoped_parent { true }
    takes_hybrid_scoped_parent { true }
    takes_name_element { true }
    takes_verbatim_rank { true }
    takes_rank { true }

    transient do
      valid_names { ["phrase name"] }
    end
    sequence(:name) { |n| valid_names[n % valid_names.length] }
   
    initialize_with { NameCategory.find_or_create_by(name: name) }
  end
end
