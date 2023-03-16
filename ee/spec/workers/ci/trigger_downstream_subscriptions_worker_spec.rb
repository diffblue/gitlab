# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerDownstreamSubscriptionsWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline_id) }

    context 'when pipeline exists' do
      let(:pipeline_id) { create(:ci_pipeline, user: create(:user)).id }

      it 'calls the trigger downstream pipeline service' do
        expect(::Ci::TriggerDownstreamSubscriptionService).to receive_message_chain(:new, :execute)

        perform
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { 1234 }

      it 'does nothing' do
        expect(::Ci::TriggerDownstreamSubscriptionService).not_to receive(:new)

        perform
      end
    end
  end
end
