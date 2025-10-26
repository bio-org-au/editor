module Loader::Name::Voting
  extend ActiveSupport::Concern

  def votable?
    ['accepted','excluded','heading'].include?(record_type)
  end

  def summary_of_votes_for_review(review)
    self.name_review_votes.includes([:org]).where(batch_review_id: review.id)
        .sort {|v1,v2| v1.org.abbrev <=> v2.org.abbrev}
        .map {|vote| {org_abbrev: vote.org.abbrev, org_name: vote.org.name, vote: (vote.vote ? 'agree' :  'disagree')} }

  end

  def frequencies_of_votes_for_review(review)
    freq = Hash.new(0)
    self.name_review_votes.where(batch_review_id: review.id).pluck(:vote).map{|vote| vote ? 'agree' : 'disagree'}.each {|x| freq[x] += 1}
    freq.map {|key, value| "#{key.capitalize}: #{value}"}.join(', ')
  end
end
