# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::ResetUsageService do
  include AfterNextHelpers

  describe '#execute' do
    subject { described_class.new(namespace).execute }

    context 'when project has namespace_statistics' do
      let_it_be(:namespace) { create(:namespace, :with_used_build_minutes_limit) }

      let_it_be(:namespace_usage) do
        create(:ci_namespace_monthly_usage, :with_warning_notification_level,
          namespace: namespace,
          amount_used: 100)
      end

      it 'clears the amount used and notification levels', :aggregate_failures do
        subject

        namespace_usage.reload
        expect(namespace_usage.amount_used).to eq(0)
        expect(namespace_usage.notification_level)
          .to eq(Ci::Minutes::Notification::PERCENTAGES.fetch(:not_set))
      end

      it 'clears legacy counters' do
        subject

        expect(namespace.namespace_statistics.reload.shared_runners_seconds).to eq(0)
      end

      it 'resets legacy timer' do
        subject

        expect(namespace.namespace_statistics.reload.shared_runners_seconds_last_reset).to be_like_time(Time.current)
      end

      it 'successfully clears minutes' do
        expect(subject).to be_truthy
      end

      it 'expires the CachedQuota' do
        expect_next(Gitlab::Ci::Minutes::CachedQuota).to receive(:expire!)

        subject
      end
    end

    context 'when project does not have namespace_statistics' do
      let(:namespace) { create(:namespace) }

      it 'successfully clears minutes' do
        expect(subject).to be_truthy
      end
    end
  end
end
