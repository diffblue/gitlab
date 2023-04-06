# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UpdateProjectAndNamespaceUsageService, feature_category: :continuous_integration do
  include ::Ci::MinutesHelpers

  let(:project) { create(:project, :private) }
  let(:namespace) { project.namespace }
  let(:build) { create(:ci_build) }
  let(:consumption_minutes) { 120 }
  let(:duration) { 1_000 }
  let(:consumption_seconds) { consumption_minutes * 60 }
  let(:namespace_amount_used) { Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id).amount_used }
  let(:project_amount_used) { Ci::Minutes::ProjectMonthlyUsage.find_or_create_current(project_id: project.id).amount_used }
  let(:service) { described_class.new(project.id, namespace.id, build.id) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    subject { service.execute(consumption_minutes, duration) }

    shared_examples 'updates legacy consumption' do
      it 'updates legacy statistics with consumption seconds' do
        expect { subject }
          .to change { project.statistics.reload.shared_runners_seconds }.by(consumption_seconds)
          .and change { namespace.reload.namespace_statistics&.shared_runners_seconds || 0 }.by(consumption_seconds)
      end
    end

    shared_examples 'updates monthly consumption' do
      it 'updates monthly usage for namespace' do
        current_usage = Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id)

        expect { subject }
          .to change { current_usage.reload.amount_used }.by(consumption_minutes)
          .and change { current_usage.reload.shared_runners_duration }.by(duration)
      end

      it 'updates monthly usage for project' do
        current_usage = Ci::Minutes::ProjectMonthlyUsage.find_or_create_current(project_id: project.id)

        expect { subject }
          .to change { current_usage.reload.amount_used }.by(consumption_minutes)
          .and change { current_usage.reload.shared_runners_duration }.by(duration)
      end
    end

    shared_examples 'does not update monthly consumption' do
      it 'does not update the usage on a monthly basis' do
        expect { subject }
          .to change { Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id).amount_used }.by(0)
          .and change { Ci::Minutes::ProjectMonthlyUsage.find_or_create_current(project_id: project.id).amount_used }.by(0)
      end
    end

    context 'when duration increased out of integer range' do
      let(:max_int) { 2147483647 }

      before do
        usage = Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id)
        usage.update!(shared_runners_duration: max_int)
      end

      it 'does not fail the service' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when statistics and usage do not have existing values' do
      it_behaves_like 'updates legacy consumption'
      it_behaves_like 'updates monthly consumption'

      context 'when project deleted' do
        let(:project) { double(id: non_existing_record_id) }
        let(:namespace) { create(:namespace) }

        it 'will complete successfully and increment namespace statistics' do
          subject

          expect(ProjectStatistics.find_by_project_id(project.id)).to be_nil
          expect(NamespaceStatistics.find_by_namespace_id(namespace.id).shared_runners_seconds).to eq(consumption_seconds)
          expect(Ci::Minutes::ProjectMonthlyUsage.find_by_project_id(project.id)).to be_nil
          expect(Ci::Minutes::NamespaceMonthlyUsage.find_by_namespace_id(namespace.id).amount_used).to eq(consumption_minutes)
        end
      end

      context 'when namespace deleted' do
        let(:namespace) { double(id: non_existing_record_id) }

        it 'will complete successfully' do
          subject

          expect(ProjectStatistics.find_by_project_id(project.id).shared_runners_seconds).to eq(consumption_seconds)
          expect(NamespaceStatistics.find_by_namespace_id(namespace.id)).to be_nil
          expect(Ci::Minutes::ProjectMonthlyUsage.find_by_project_id(project.id).amount_used).to eq(consumption_minutes)
          expect(Ci::Minutes::NamespaceMonthlyUsage.find_by_namespace_id(namespace.id).amount_used).to eq(consumption_minutes)
        end
      end

      context 'when project and namespace deleted' do
        let(:project) { double(id: non_existing_record_id) }
        let(:namespace) { double(id: non_existing_record_id) }

        it 'will complete successfully' do
          subject

          expect(ProjectStatistics.find_by_project_id(project.id)).to be_nil
          expect(NamespaceStatistics.find_by_namespace_id(namespace.id)).to be_nil
          expect(Ci::Minutes::ProjectMonthlyUsage.find_by_project_id(project.id)).to be_nil
          expect(Ci::Minutes::NamespaceMonthlyUsage.find_by_namespace_id(namespace.id).amount_used).to eq(consumption_minutes)
        end
      end

      context 'when on .com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'sends a minute notification email' do
          expect_next_instance_of(Ci::Minutes::EmailNotificationService) do |service|
            expect(service).to receive(:execute)
          end

          subject
        end

        context 'when an error is raised by the email notification' do
          before do
            allow_next_instance_of(Ci::Minutes::EmailNotificationService) do |service|
              allow(service).to receive(:execute).and_raise(StandardError)
            end
          end

          it 'rescues and tracks the exception' do
            expect(::Gitlab::ErrorTracking)
              .to receive(:track_and_raise_for_dev_exception)
              .with(an_instance_of(StandardError), project_id: project.id, namespace_id: namespace.id, build_id: build.id)

            subject
          end
        end
      end

      context 'when not on .com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'does not send a minute notification email' do
          expect(Ci::Minutes::EmailNotificationService).not_to receive(:new)

          subject
        end
      end
    end

    context 'when statistics and usage have existing values' do
      let(:namespace) { create(:namespace, shared_runners_minutes_limit: 100) }
      let(:project) { create(:project, :private, namespace: namespace) }
      let(:existing_usage_in_seconds) { 100 }
      let(:existing_usage_in_minutes) { (100.to_f / 60).round(2) }

      before do
        project.statistics.update!(shared_runners_seconds: existing_usage_in_seconds)
        create(:ci_project_monthly_usage, project: project, amount_used: existing_usage_in_minutes)

        set_ci_minutes_used(namespace, existing_usage_in_minutes)
      end

      it 'does not create nested transactions', :delete do
        expect(ApplicationRecord.connection.transaction_open?).to be false

        queries = ActiveRecord::QueryRecorder.new do
          subject
        end

        savepoints = queries.occurrences.keys.flatten.select do |query|
          query.include?('SAVEPOINT')
        end

        expect(savepoints).to be_empty
      end

      context 'behaves idempotently' do
        let(:cache_key) { service.idempotency_cache_key }

        context 'when update has not been performed yet' do
          it_behaves_like 'updates legacy consumption'
          it_behaves_like 'updates monthly consumption'

          it 'tracks that the update is done' do
            Gitlab::Redis::SharedState.with do |redis|
              expect(redis.get(cache_key)).not_to be_present
            end

            subject

            Gitlab::Redis::SharedState.with do |redis|
              expect(redis.get(cache_key)).to be_present
            end
          end
        end

        context 'when update has previously been performed' do
          before do
            Gitlab::Redis::SharedState.with do |redis|
              redis.set(cache_key, 1)
            end
          end

          it_behaves_like 'does not update monthly consumption'
          it_behaves_like 'updates legacy consumption' # not idempotent / to be removed

          it 'logs the event' do
            expect(::Gitlab::AppJsonLogger)
              .to receive(:info)
              .with(event: 'ci_minutes_consumption_already_updated', build_id: build.id)
              .and_call_original

            subject
          end
        end
      end
    end
  end
end
