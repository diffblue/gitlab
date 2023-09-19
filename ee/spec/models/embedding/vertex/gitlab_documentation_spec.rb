# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Embedding::Vertex::GitlabDocumentation, :clean_gitlab_redis_shared_state, type: :model, feature_category: :duo_chat do
  let_it_be(:version) { 111 }
  let_it_be(:metadata1) { { source: "source1" } }
  let_it_be(:metadata2) { { source: "source2" } }

  let_it_be(:current_records) do
    create_list(
      :vertex_gitlab_documentation, 2, version: version, metadata: metadata1, embedding: Array.new(768, -0.000999)
    )
  end

  let_it_be(:previous_records) do
    create_list(
      :vertex_gitlab_documentation, 3, version: version - 1, metadata: metadata2, embedding: Array.new(768, 0.000333)
    )
  end

  describe 'scopes' do
    describe '.neighbor_for' do
      subject(:neighbors) do
        described_class.neighbor_for(question.embedding, limit: limit)
      end

      let_it_be(:question) { build(:vertex_gitlab_documentation) }
      let(:limit) { 10 }

      it 'calls nearest_neighbors for question' do
        create_list(:vertex_gitlab_documentation, 2)

        expect(described_class).to receive(:nearest_neighbors).with(
          :embedding, question.embedding, distance: 'cosine').and_call_original.once

        neighbors
      end

      context 'with a far away embedding' do
        it 'returns all neighbors' do
          expect(neighbors).to match_array([current_records, previous_records].flatten)
        end

        context 'with a limit of one' do
          let(:limit) { 1 }

          it 'does not return the far neighbor' do
            expect(neighbors).to match_array(previous_records.first)
          end
        end
      end
    end

    describe '.current' do
      it 'is empty' do
        current = described_class.current

        expect(current.count).to eq(0)
      end

      context 'when there are records matching the current version' do
        before do
          allow(described_class).to receive(:current_version).and_return(version)
        end

        it 'returns matching records' do
          current = described_class.current

          expect(current).to eq(current_records)
        end
      end
    end

    describe '.previous' do
      it 'is empty' do
        previous = described_class.previous

        expect(previous.count).to eq(0)
      end

      context 'when there are records matching the previous version' do
        before do
          allow(described_class).to receive(:current_version).and_return(version)
        end

        it 'returns matching records' do
          previous = described_class.previous

          expect(previous).to eq(previous_records)
        end
      end
    end

    describe '.for_source' do
      it 'returns matching records' do
        embeddings = described_class.for_source('source1')

        expect(embeddings.count).to eq(2)
        expect(embeddings.map { |em| em.metadata["source"] }.uniq).to match_array(%w[source1])
      end
    end

    describe '.for_sources' do
      it 'returns matching records' do
        embeddings = described_class.for_sources(%w[source1 source2])

        expect(embeddings.count).to eq(5)
        expect(embeddings.map { |em| em.metadata["source"] }.uniq).to match_array(%w[source1 source2])
      end
    end

    describe '.for_version' do
      it 'returns matching records' do
        current = described_class.for_version(version)

        expect(current.count).to eq(2)
      end
    end
  end

  describe '.current_version' do
    it 'returns 1' do
      expect(described_class.current_version).to eq(1)
    end
  end
end
