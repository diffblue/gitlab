# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::InitializeStackService do
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    subject { described_class.new(container: project).execute }

    context 'when feature flag is enabled' do
      it 'enqueues a job' do
        expect(::ProductAnalytics::InitializeAnalyticsWorker).to receive(:perform_async).with(project.id)

        subject
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(jitsu_connection_proof_of_concept: false)
      end

      it 'does not enqueue a job' do
        expect(::ProductAnalytics::InitializeAnalyticsWorker).not_to receive(:perform_async)

        subject
      end
    end
  end
end
