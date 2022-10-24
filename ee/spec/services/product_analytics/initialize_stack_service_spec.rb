# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::InitializeStackService do
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    subject { described_class.new(container: project).execute }

    before do
      stub_licensed_features(product_analytics: true)
      stub_ee_application_setting(product_analytics_enabled: true)
    end

    context 'when feature flag is enabled' do
      it 'enqueues a job' do
        expect(::ProductAnalytics::InitializeAnalyticsWorker).to receive(:perform_async).with(project.id)

        subject
      end
    end

    context 'when feature is unlicensed' do
      before do
        stub_licensed_features(product_analytics: false)
      end

      it 'does not enqueue a job' do
        expect(::ProductAnalytics::InitializeAnalyticsWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when enable_product_analytics application setting is false' do
      before do
        stub_ee_application_setting(product_analytics_enabled: false)
      end

      it 'does not enqueue a job' do
        expect(::ProductAnalytics::InitializeAnalyticsWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(cube_api_proxy: false)
      end

      it 'does not enqueue a job' do
        expect(::ProductAnalytics::InitializeAnalyticsWorker).not_to receive(:perform_async)

        subject
      end
    end
  end
end
