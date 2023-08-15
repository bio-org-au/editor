# frozen_string_literal: true

# Name author associations and methods
# covering the various types of authors a name may have
module InstanceInTaxonomy
  extend ActiveSupport::Concern

  def profile?
    tree_elements.size > 0
  end
end
