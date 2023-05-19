# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Embedding::TanukiBotMvc, :clean_gitlab_redis_shared_state, type: :model, feature_category: :global_search do
  let(:version) { 111 }

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

    describe '.current' do
      let!(:current_records) { create_list(:tanuki_bot_mvc, 5, version: version) }
      let!(:previous_records) { create_list(:tanuki_bot_mvc, 3, version: version - 1) }

      it 'is empty' do
        current = described_class.current

        expect(current.count).to eq(0)
      end

      context 'when there are records matching the current version' do
        before do
          allow(described_class).to receive(:get_current_version).and_return(version)
        end

        it 'returns matching records' do
          current = described_class.current

          expect(current).to eq(current_records)
        end
      end
    end

    describe '.previous' do
      let!(:current_records) { create_list(:tanuki_bot_mvc, 5, version: version) }
      let!(:previous_records) { create_list(:tanuki_bot_mvc, 3, version: version - 1) }

      it 'is empty' do
        previous = described_class.previous

        expect(previous.count).to eq(0)
      end

      context 'when there are records matching the previous version' do
        before do
          allow(described_class).to receive(:get_current_version).and_return(version)
        end

        it 'returns matching records' do
          previous = described_class.previous

          expect(previous).to eq(previous_records)
        end
      end
    end
  end

  describe '.get_current_version' do
    it 'returns 0' do
      expect(described_class.get_current_version).to eq(0)
    end

    context 'when it exists in redis' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class.current_version_cache_key, version)
        end
      end

      it 'returns the value' do
        expect(described_class.get_current_version).to eq(version)
      end
    end
  end

  describe '.set_current_version!' do
    it 'updates the version in redis' do
      expect(described_class.get_current_version).to eq(0)

      described_class.set_current_version!(version)

      expect(described_class.get_current_version).to eq(version)
    end
  end
end
