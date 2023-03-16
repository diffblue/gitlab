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

    it 'delegates to Ci::Minutes::BatchResetService' do
      expect_next_instance_of(Ci::Minutes::BatchResetService) do |service|
        expect(service)
          .to receive(:execute!)
          .with(ids_range: ((first_namespace.id)..(last_namespace.id)))
      end

      worker.perform(first_namespace.id, last_namespace.id)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [first_namespace.id, last_namespace.id] }

      shared_examples 'resets CI minutes and notification' do
        it 'resets CI minutes used and notification data' do
          subject

          namespace.reset

          expect(namespace.namespace_statistics.shared_runners_seconds).to eq 0

          expect(namespace.last_ci_minutes_notification_at).to be_nil
          expect(namespace.last_ci_minutes_usage_notification_level).to be_nil
        end
      end

      it_behaves_like 'resets CI minutes and notification' do
        let(:namespace) { first_namespace }
      end

      it_behaves_like 'resets CI minutes and notification' do
        let(:namespace) { last_namespace }
      end

      it 'does not recalculate purchased minutes for the namespace exceeding the monthly minutes' do
        subject

        expect(first_namespace.reset.extra_shared_runners_minutes_limit).to eq 50
      end
    end
  end
end
