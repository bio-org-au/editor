module Loader::Batch::SortKey
  extend ActiveSupport::Concern

  UPDATE_SYN_SORT_KEYS = <<-SQL
update loader_name
   set sort_key = (select sort_key||' '||usage_order
                     from taxon_name_usage_v t
                     join loader_name_match m
                       on t.instance_id = m.instance_id
                     join loader_name l
                       on m.loader_name_id = l.id
                    where loader_name.id = m.loader_name_id)
 where loader_name.id in
                  (select ln.id
                     from loader_name ln
                    join loader_name_match lnm
                      on ln.id = lnm.loader_name_id
                   where ln.record_type in ('synonym')
   and ln.loader_batch_id = ?
)
SQL


  # Synonyms sort_key will be supplemented with the 
  # taxon_name_usage_v.usage_order value
  # for better ordering
  def refresh_synonym_sort_keys
    Loader::Name.set_short_sort_key_for_synonyms(self)
    sanitized_s = ActiveRecord::Base::sanitize_sql([UPDATE_SYN_SORT_KEYS,
                                                    self.id])
    ActiveRecord::Base.connection.execute(sanitized_s)
    Loader::Name.set_sort_keys_if_blank(self, 'synonym')
  end
end
