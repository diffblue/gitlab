# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Embedding::TanukiBotMvc, type: :model, feature_category: :global_search do
  describe 'scopes' do
    describe '.neighbor_for' do
      subject(:neighbors) do
        described_class.neighbor_for(question.embedding, limit: limit, minimum_distance: minimum_distance)
      end

      let_it_be(:question) { build(:tanuki_bot_mvc) }
      let(:limit) { 10 }
      let(:minimum_distance) { -1 }

      it 'calls nearest_neighbors for question' do
        create_list(:tanuki_bot_mvc, 2)

        expect(described_class).to receive(:nearest_neighbors)
          .with(:embedding, question.embedding, distance: 'inner_product').and_call_original.once

        neighbors
      end

      context 'with a far away embedding' do
        let_it_be(:far) { create(:tanuki_bot_mvc, embedding: Array.new(1536, -0.000999)) }
        let_it_be(:near) { create(:tanuki_bot_mvc, embedding: Array.new(1536, 0.000333)) }

        it 'returns all neighbors' do
          expect(neighbors).to match_array([near, far])
        end

        context 'with a limit of one' do
          let(:limit) { 1 }

          it 'does not return the far neighbor' do
            expect(neighbors).to match_array(near)
          end
        end

        context 'with a minimum distance' do
          let(:minimum_distance) { 0.1 }

          it 'does not return the far neighbor' do
            expect(neighbors).to match_array(near)
          end
        end
      end
    end
  end
end
