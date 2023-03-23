# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::NoteIndex, feature_category: :global_search do
  it_behaves_like 'a search index'

  describe '.indexed_class' do
    it 'is configured correctly' do
      expect(described_class.indexed_class).to eq(Note)
    end
  end
end
