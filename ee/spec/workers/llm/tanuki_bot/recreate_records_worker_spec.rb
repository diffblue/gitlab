# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::TanukiBot::RecreateRecordsWorker, feature_category: :global_search do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always

  describe '#perform' do
    before do
      stub_const("#{described_class}::DOC_DIRECTORY", './ee/spec/fixtures/tanuki_bot_docs')
      allow(::Gitlab::Llm::ContentParser).to receive(:parse_and_split).and_return([item])
      allow(::Embedding::TanukiBotMvc).to receive(:get_current_version).and_return(version)
    end

    let(:logger) { described_class.new.send(:logger) }
    let(:version) { 111 }
    let(:next_version) { version + 1 }
    let(:class_instance) { described_class.new }
    let(:item) do
      {
        content: "# Heading 1\n",
        metadata: { type: "reference", group: "Unknown", info: "Test Information", title: "Heading 1" },
        url: 'a.url'
      }
    end

    subject(:perform) { class_instance.perform }

    it 'does not enqueue any workers' do
      expect(Llm::TanukiBot::UpdateWorker).not_to receive(:perform_in)

      perform
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

        it 'does not create any records or enqueue any workers' do
          expect(Llm::TanukiBot::UpdateWorker).not_to receive(:perform_in)

          expect { perform }.not_to change { ::Embedding::TanukiBotMvc.count }
        end
      end
    end

    context 'with the feature available' do
      before do
        allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(true)
      end

      it 'creates a record and enqueues workers' do
        expect(::Gitlab::Llm::ContentParser).to receive(:parse_and_split).once
        expect(Llm::TanukiBot::UpdateWorker).to receive(:perform_in).with(anything, anything, next_version).once

        expect { perform }.to change { ::Embedding::TanukiBotMvc.count }.from(0).to(1)
      end

      it 'has the correct attributes' do
        allow(Llm::TanukiBot::UpdateWorker).to receive(:perform_in)

        perform

        expect(::Embedding::TanukiBotMvc.count).to eq(1)

        record = ::Embedding::TanukiBotMvc.first
        expect(record.metadata).to eq(item[:metadata].deep_stringify_keys)
        expect(record.embedding).to eq(nil)
        expect(record.content).to eq(item[:content])
        expect(record.url).to eq(item[:url])
        expect(record.version).to eq(next_version)
      end

      context 'with more than one items' do
        before do
          allow(::Gitlab::Llm::ContentParser).to receive(:parse_and_split).and_return([item, item])
        end

        it 'creates two records, and enqueues workers' do
          expect(::Gitlab::Llm::ContentParser).to receive(:parse_and_split).once
          expect(Llm::TanukiBot::UpdateWorker).to receive(:perform_in).twice

          expect { perform }.to change { ::Embedding::TanukiBotMvc.count }.from(0).to(2)
        end

        it_behaves_like 'an idempotent worker' do
          before do
            allow(::Gitlab::Llm::ContentParser).to receive(:parse_and_split).and_return([item, item])
            allow(Llm::TanukiBot::UpdateWorker).to receive(:perform_in)
          end

          it 'creates two records' do
            expect { perform }.to change { ::Embedding::TanukiBotMvc.count }.from(0).to(2)
          end
        end
      end

      context 'when the exclusive lease is already locked for the version' do
        before do
          lock_name = "#{described_class.name.underscore}/version/#{next_version}"
          allow(class_instance).to receive(:in_lock).with(lock_name, ttl: 10.minutes, sleep_sec: 1)
        end

        it 'does nothing' do
          expect(Llm::TanukiBot::UpdateWorker).not_to receive(:perform_in)

          expect { perform }.not_to change { ::Embedding::TanukiBotMvc.count }
        end
      end
    end
  end
end
