# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenAi::ClearConversationsWorker, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  subject { described_class.new }

  describe '#perform' do
    let!(:test_start) { Time.current }
    let!(:expired_time) { Time.current - (described_class::EXPIRATION_DURATION + 10.days) }

    let!(:old_message) do
      travel_to(expired_time) do
        create(:message)
      end
    end

    let!(:old_message2) do
      travel_to(expired_time) do
        create(:message)
      end
    end

    let!(:new_message) do
      travel_to(test_start) do
        create(:message)
      end
    end

    let(:perform) do
      travel_to(test_start) do
        subject.perform
      end
    end

    it 'destroys expired messages' do
      perform

      expect { old_message.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { old_message2.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(new_message.reload).to eq new_message
    end

    context 'when more messages than batch size' do
      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 1)
      end

      it 'destroys old messages' do
        perform

        expect { old_message.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { old_message2.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when over time limit' do
      before do
        allow_next_instance_of(Analytics::CycleAnalytics::RuntimeLimiter) do |l|
          allow(l).to receive(:over_time?).and_return(true)
        end
      end

      it 'stops working' do
        perform

        expect(old_message.reload).to eq old_message
      end
    end
  end
end
