module Loader::Name::Voting
  extend ActiveSupport::Concern

  def votable?
    ['accepted','excluded'].include?(record_type)
  end
end
