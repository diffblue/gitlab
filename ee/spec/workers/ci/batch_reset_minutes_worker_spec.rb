# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BatchResetMinutesWorker, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:first_namespace) do
      create(:namespace,
        id: 1,
        shared_runners_minutes_limit: 100,
        extra_shared_runners_minutes_limit: 50,
        last_ci_minutes_notification_at: Time.current,
        last_ci_minutes_usage_notification_level: 30)
    end

    let(:last_namespace) do
      create(:namespace,
        id: 10,
        shared_runners_minutes_limit: 100,
        extra_shared_runners_minutes_limit: 50,
        last_ci_minutes_notification_at: Time.current,
        last_ci_minutes_usage_notification_level: 30)
    end

    let!(:first_namespace_statistics) do
      create(:namespace_statistics, namespace: first_namespace, shared_runners_seconds: 120.minutes)
    end

    let!(:last_namespace_statistics) do
      create(:namespace_statistics, namespace: last_namespace, shared_runners_seconds: 90.minutes)
    end

    it 'does nothing and will be removed in the next release' do
      expect { worker.perform(first_namespace.id, last_namespace.id) }.not_to raise_error
    end
  end
end
