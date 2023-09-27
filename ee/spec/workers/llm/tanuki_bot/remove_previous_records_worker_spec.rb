# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::TanukiBot::RemovePreviousRecordsWorker, feature_category: :duo_chat do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always

  describe '#perform' do
    let(:logger) { described_class.new.send(:logger) }
    let(:version) { 111 }
    let!(:records) { create_list(:tanuki_bot_mvc, 3, version: version) }
    let!(:previous_records) { create_list(:tanuki_bot_mvc, 5, version: version - 1) }

    subject(:perform) { described_class.new.perform }

    before do
      allow(::Embedding::TanukiBotMvc).to receive(:get_current_version).and_return(version)
    end

    it 'does not delete previous records' do
      expect { perform }.not_to change { ::Embedding::TanukiBotMvc.count }
    end

    describe 'checks' do
      where(:openai_experimentation_enabled) do
        [[false], [true]]
      end

      with_them do
        before do
          stub_feature_flags(openai_experimentation: openai_experimentation_enabled)
          allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(false)
        end

        it 'does not delete previous records' do
          expect { perform }.not_to change { ::Embedding::TanukiBotMvc.count }
        end
      end
    end

    context 'with the feature available' do
      before do
        allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(true)
      end

      it 'deletes records with version less than current version' do
        expect(::Embedding::TanukiBotMvc.previous).not_to be_empty

        expect { perform }.to change { ::Embedding::TanukiBotMvc.count }.from(8).to(3)

        expect(::Embedding::TanukiBotMvc.previous).to be_empty
      end

      it_behaves_like 'an idempotent worker' do
        it 'deletes records with version less than current version' do
          expect(::Embedding::TanukiBotMvc.previous).not_to be_empty

          expect { perform }.to change { ::Embedding::TanukiBotMvc.count }.from(8).to(3)

          expect(::Embedding::TanukiBotMvc.previous).to be_empty
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

          expect { perform }.to change { ::Embedding::TanukiBotMvc.count }.from(8).to(7)
        end
      end
    end
  end
end
