# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Embedding::TanukiBotMvc, type: :model, feature_category: :global_search do
  describe 'scopes' do
    describe '.neighbor_for' do
      let_it_be(:question) { build(:tanuki_bot_mvc) }

      it 'calls nearest_neighbors for question' do
        create_list(:tanuki_bot_mvc, 2)

        expect(described_class).to receive(:nearest_neighbors)
          .with(:embedding, question.embedding, distance: 'inner_product').once

        described_class.neighbor_for(question.embedding)
      end

      context 'with a far away embedding' do
        let_it_be(:far_embedding) { create(:tanuki_bot_mvc, embedding: Array.new(1536, -0.999)) }
        let_it_be(:close_embedding) { create(:tanuki_bot_mvc, embedding: Array.new(1536, 0.333)) }

        it 'does not return the far neighbor' do
          expect(described_class.neighbor_for(question.embedding).limit(1)).to match_array(close_embedding)
        end
      end
    end
  end
end
