# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::Embedding::GitlabDocumentation::CleanupPreviousVersionsRecordsWorker, feature_category: :duo_chat do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always

  describe '#perform' do
    let(:logger) { described_class.new.send(:logger) }
    let(:version) { 111 }
    let!(:records) { create_list(:vertex_gitlab_documentation, 3, version: version) }
    let!(:previous_records) { create_list(:vertex_gitlab_documentation, 5, version: version - 1) }

    subject(:perform) { described_class.new.perform }

    before do
      allow(::Embedding::Vertex::GitlabDocumentation).to receive(:current_version).and_return(version)
    end

    it 'does not delete previous records' do
      expect { perform }.not_to change { ::Embedding::Vertex::GitlabDocumentation.count }
    end

    describe 'checks' do
      using RSpec::Parameterized::TableSyntax

      where(:openai_experimentation_enabled, :vertex_embeddings_enabled, :feature_available) do
        false | false | false
        false | false | true
        false | true  | false
        true  | false | false
      end

      with_them do
        before do
          stub_feature_flags(openai_experimentation: openai_experimentation_enabled)
          stub_feature_flags(create_embeddings_with_vertex_ai: vertex_embeddings_enabled)
          allow(License).to receive(:feature_available?).with(:ai_chat).and_return(feature_available)
        end

        it 'does not delete previous records' do
          expect { perform }.not_to change { ::Embedding::Vertex::GitlabDocumentation.count }
        end
      end
    end

    context 'with the feature available' do
      before do
        allow(License).to receive(:feature_available?).with(:ai_chat).and_return(true)
      end

      it 'deletes records with version less than current version' do
        expect(::Embedding::Vertex::GitlabDocumentation.previous).not_to be_empty

        expect { perform }.to change { ::Embedding::Vertex::GitlabDocumentation.count }.from(8).to(3)

        expect(::Embedding::Vertex::GitlabDocumentation.previous).to be_empty
      end

      it_behaves_like 'an idempotent worker' do
        it 'deletes records with version less than current version' do
          expect(::Embedding::Vertex::GitlabDocumentation.previous).not_to be_empty

          expect { perform }.to change { ::Embedding::Vertex::GitlabDocumentation.count }.from(8).to(3)

          expect(::Embedding::Vertex::GitlabDocumentation.previous).to be_empty
        end
      end

      it 'does not enqueue another worker' do
        expect(described_class).not_to receive(:perform_in)

        perform
      end

      context 'when there are more records than the batch size' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it 'deletes the first batch and then enqueues another worker' do
          expect(described_class).to receive(:perform_in).with(10.seconds).once

          expect { perform }.to change { ::Embedding::Vertex::GitlabDocumentation.count }.from(8).to(7)
        end
      end
    end
  end
end
