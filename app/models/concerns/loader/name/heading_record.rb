module Loader::Name::HeadingRecord
  extend ActiveSupport::Concern
  class_methods do
    def create_family_heading(params)
      heading = Loader::Name.new
      heading.record_type = 'heading'
      heading.simple_name = heading.full_name = heading.family = params[:family]
      heading.simple_name_as_loaded = heading.simple_name
      heading.loader_batch_id = params[:loader_batch_id]
      heading.rank = 'family'
      heading.save!
    end
  end
end

