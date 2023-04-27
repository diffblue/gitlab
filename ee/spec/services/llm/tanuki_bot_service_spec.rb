# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::TanukiBotService, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let_it_be(:options) { { question: 'A question' } }

  subject { described_class.new(user, user, options) }

  before do
    stub_licensed_features(ai_tanuki_bot: true)
  end

  describe '#perform' do
    it 'schedules a job' do
      expect(Llm::CompletionWorker).to receive(:perform_async).with(
        user.id, user.id, 'User', :tanuki_bot, options
      )

      expect(subject.execute).to be_success
    end

    context 'when openai_experimentation feature flag is disabled' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end

    context 'when tanuki_bot feature flag is disabled' do
      before do
        stub_feature_flags(tanuki_bot: false)
      end

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end

    context 'when tanuki_bot licensed feature is disabled' do
      before do
        stub_licensed_features(ai_tanuki_bot: false)
      end

      it 'returns an error' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end
  end
end
