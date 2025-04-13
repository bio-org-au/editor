require 'rails_helper'

RSpec.describe Author, type: :model do
  describe '#referenced_in_any_instance?' do
    let(:author) { FactoryBot.create(:author) }
    let(:reference) { FactoryBot.create(:reference, author: author) }

    context 'when the author has references associated with instances' do
      before do
        FactoryBot.create(:instance, reference: reference)
      end

      it 'returns true' do
        expect(author.referenced_in_any_instance?).to be true
      end
    end

    context 'when the author has references but none are associated with instances' do
      it 'returns false' do
        expect(author.referenced_in_any_instance?).to be false
      end
    end

    context 'when the author has no references' do
      it 'returns false' do
        expect(author.referenced_in_any_instance?).to be false
      end
    end
  end
end
