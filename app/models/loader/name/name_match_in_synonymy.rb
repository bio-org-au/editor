

# Result is true if the supplied name_id is "in synonymy" in the
# current accepted tree. Result is false otherwise.
#
# Intended for use building the Details tab for loader_name records.
#
# This sql is comolex enough to take some wrangling and comes 
# from work on the name-match-in-syn: directive, in fact from the 
# join select that I used to work out the sub-query required for 
# name-match-in-syn:
class Loader::Name::NameMatchInSynonymy

  attr_reader :result

  RAW_SELECT = "SELECT count(*) qty
  FROM loader_name
 WHERE exists (
       select null
       from loader_name_match
       join name pref_name
       on loader_name_match.name_id = pref_name.id
       join instance pref_name_instance
       on pref_name_instance.name_id = loader_name_match.name_id
       join instance_type pni_type
       on pref_name_instance.instance_type_id = pni_type.id
       join tree_join_v
       on pref_name_instance.cited_by_id = tree_join_v.instance_id
       join name name_on_tree
       on tree_join_v.name_id = name_on_tree.id
       join instance tree_name_instance
       on tree_name_instance.name_id = name_on_tree.id
 WHERE pref_name.id = ?
   and loader_name.id  = loader_name_match.loader_name_id
   and not loader_name_match.drafted
   and not loader_name_match.manually_drafted
   and tree_join_v.tree_version_id = tree_join_v.current_tree_version_id
   and tree_join_v.accepted_tree
   and pni_type.synonym
   and not pni_type.pro_parte)"

  def initialize(name_id)
    @name_id = name_id
    main
  end

  def main
    query = Loader::Name.send(:sanitize_sql,[RAW_SELECT, @name_id])
    connection = ActiveRecord::Base.connection
    query_result = connection.execute(query).first
    @result = query_result['qty'] > 0
  end
end
