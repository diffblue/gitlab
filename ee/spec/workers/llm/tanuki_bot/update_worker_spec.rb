# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::TanukiBot::UpdateWorker, feature_category: :ai_abstraction_layer do
  let(:logger) { described_class.new.send(:logger) }
  let(:class_instance) { described_class.new }
  let(:openai_client) { ::Gitlab::Llm::OpenAi::Client.new(nil) }
  let_it_be_with_reload(:record) { create(:tanuki_bot_mvc) }
  let!(:records) { create_list(:tanuki_bot_mvc, 4, version: version) }
  let(:embedding) { Array.new(1536, 0.5) }
  let(:version) { 111 }
  let(:response) { { "data" => [{ "embedding" => embedding }] } }
  let(:status_code) { 200 }
  let(:success) { true }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    subject(:perform) { class_instance.perform(record.id, version) }

    before do
      allow(logger).to receive(:info)
      allow(openai_client).to receive(:embeddings).and_return(response)
      allow(response).to receive(:code).and_return(status_code)
      allow(response).to receive(:success?).and_return(success)
      allow(::Gitlab::Llm::OpenAi::Client).to receive(:new).and_return(openai_client)
    end

    it 'does not make a call to the embedding API or update the record' do
      expect(openai_client).not_to receive(:embeddings)

      expect { perform }.not_to change { record.reload.embedding }
    end

    describe 'checks' do
      using RSpec::Parameterized::TableSyntax

      where(:openai_experimentation_enabled, :tanuki_bot_enabled, :feature_available) do
        false | false | false
        false | true | false
        true | false | false
      end

      with_them do
        before do
          stub_feature_flags(openai_experimentation: openai_experimentation_enabled)
          stub_feature_flags(tanuki_bot: tanuki_bot_enabled)
          allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(feature_available)
        end

        it 'does not make a call to the embedding API or update the record' do
          expect(openai_client).not_to receive(:embeddings)

          expect { perform }.not_to change { record.reload.embedding }
        end
      end
    end

    context 'with the feature available' do
      before do
        allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(true)
      end

      it 'makes a call to the embedding API' do
        expect(openai_client).to receive(:embeddings).with(hash_including(input: record.content)).and_return(response)

        perform
      end

      it 'updates the record' do
        expect { perform }.to change { record.reload.embedding }.to(embedding)
      end

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end

      it 'sends a log message' do
        expect(logger).to receive(:info)
          .with(hash_including({ "version" => version, "message" => "Updated current version" }))

        perform
      end

      it 'updates current version' do
        expect(::Embedding::TanukiBotMvc).to receive(:set_current_version!).with(version).once

        perform
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [record.id, version] }

        it 'updates the record' do
          expect(::Embedding::TanukiBotMvc).to receive(:set_current_version!).with(version).once

          expect { perform }.to change { record.reload.embedding }.to(embedding)
        end
      end

      context 'when the exclusive lease is already locked for the version' do
        before do
          lock_name = "#{described_class.name.underscore}/version/#{version}"
          allow(class_instance).to receive(:in_lock).with(lock_name, sleep_sec: 1)
        end

        it 'does not set current version' do
          expect(::Embedding::TanukiBotMvc).not_to receive(:set_current_version!)

          perform
        end
      end

      context 'when some of the records have nil embedding' do
        before do
          records.first.update!(embedding: nil)
        end

        it 'does not set current version' do
          expect(::Embedding::TanukiBotMvc).not_to receive(:set_current_version!)

          perform
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
