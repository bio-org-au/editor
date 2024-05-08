module Loader::Name::SeqGapMaker
  extend ActiveSupport::Concern

  included do
    def self.multiply_seqs_by_10(batch)
      update_s = "update loader_name \
                     set seq = seq * 10 \
                   where loader_batch_id = \
                           (select id \
                              from loader_batch \
                             where lower(name) = ?)"
      sanitized_s = ActiveRecord::Base::sanitize_sql(
        [update_s, batch.name.downcase])
      ActiveRecord::Base.connection.execute(sanitized_s)
    end
  end
end
