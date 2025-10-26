
#
# Names can be in a loader batch
module Loader::Name::ReviewCommentContext
  extend ActiveSupport::Concern

  def contexts
    case record_type
    when 'accepted'
      ['accepted','concept-note','distribution']
    when 'excluded'
      ['excluded','concept-note']
    else
      [self.record_type]
    end
  end
end
