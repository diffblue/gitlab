# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::Embedding::GitlabDocumentation::SetEmbeddingsOnTheRecordWorker, feature_category: :duo_chat do
  let(:success) { true }
  let(:version) { 112 }
  let(:older_version) { 111 }
  let(:status_code) { 200 }
  let(:embedding) { Array.new(768, 0.5) }
  let(:logger) { described_class.new.send(:logger) }
  let(:class_instance) { described_class.new }
  let(:ai_client) { ::Gitlab::Llm::VertexAi::Client.new(nil) }
  let(:response) { { "predictions" => [{ "embeddings" => { "values" => embedding } }] } }

  let(:metadata) { { source: '/ee/spec/fixtures/gitlab_documentation/non_existent.md' } }

  let!(:record) { create(:vertex_gitlab_documentation, version: version, metadata: metadata) }
  let!(:records) { create_list(:vertex_gitlab_documentation, 4, version: version, metadata: metadata) }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    subject(:perform) { class_instance.perform(record.id, version) }

    before do
      allow(logger).to receive(:info)
      allow(ai_client).to receive(:text_embeddings).and_return(response)
      allow(response).to receive(:code).and_return(status_code)
      allow(response).to receive(:success?).and_return(success)
      allow(::Gitlab::Llm::VertexAi::Client).to receive(:new).and_return(ai_client)
      allow(::Embedding::Vertex::GitlabDocumentation).to receive(:current_version).and_return(older_version)
    end

    it 'does not make a call to the embedding API or update the record' do
      expect(ai_client).not_to receive(:text_embeddings)

      expect { perform }.not_to change { record.reload.embedding }
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

        it 'does not make a call to the embedding API or update the record' do
          expect(ai_client).not_to receive(:text_embeddings)

          expect { perform }.not_to change { record.reload.embedding }
        end
      end
    end

    context 'with the feature available' do
      before do
        allow(License).to receive(:feature_available?).with(:ai_chat).and_return(true)
      end

      it 'makes a call to the embedding API' do
        content = record.content
        expect(ai_client).to receive(:text_embeddings).with(hash_including(content: content)).and_return(response)

        perform
      end

      it 'updates the record' do
        content = record.content
        expect(ai_client).to receive(:text_embeddings).with(hash_including(content: content)).and_return(response)

        expect { perform }.to change { record.reload.embedding }.to(embedding)
      end

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [record.id, version] }

        it 'updates the record' do
          expect { perform }.to change { record.reload.embedding }.to(embedding)
        end
      end

      context 'when there are older version embeddings' do
        let!(:old_records) { create_list(:vertex_gitlab_documentation, 2, version: older_version, metadata: metadata) }

        context 'and some of the records have nil embedding' do
          before do
            records.first.update!(embedding: nil)
          end

          it 'updates the record' do
            expect { perform }.to change { record.reload.embedding }.to(embedding)
          end

          it 'does not cleanup old records' do
            expect { perform }.not_to change {
              ::Embedding::Vertex::GitlabDocumentation.id_in(old_records.pluck(:id)).count
            }
          end

          it 'does not update record version' do
            expect { perform }.not_to change { record.reload.version }
          end

          it 'does not update version on other records related to this record\'s filename' do
            expect { perform }.not_to change { ::Embedding::Vertex::GitlabDocumentation.for_version(version).count }
          end
        end

        context 'when all records have the embeddings' do
          it 'updates the record' do
            expect { perform }.to change { record.reload.embedding }.to(embedding)
          end

          it 'cleanups up old records' do
            expect { perform }.to change {
              ::Embedding::Vertex::GitlabDocumentation.id_in(old_records.pluck(:id)).count
            }.by(-2)
          end

          it 'updates record version' do
            expect { perform }.to change { record.reload.version }.from(version).to(older_version)
          end

          it 'updates version on other records related to this record\'s filename' do
            expect { perform }.to change {
              ::Embedding::Vertex::GitlabDocumentation.for_version(version).count
              # -5 = 1(:record) - 4(:records)
            }.by(-5).and(
              # 3 = -2(:old_records) +1(:record) + 4(:records)
              change { ::Embedding::Vertex::GitlabDocumentation.for_version(older_version).count }.by(3)
            )
          end
        end
      end

      context 'when the client responds with an error' do
        let(:response) { { error: { message: 'something went wrong' } } }
        let(:status_code) { 500 }
        let(:success) { false }

        it 'raises an error' do
          expect { perform }.to raise_error(StandardError, /something went wrong/)
        end
      end
    end
  end
end
