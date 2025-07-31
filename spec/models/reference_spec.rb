# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reference, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:products).with_foreign_key('reference_id') }
  end
end
