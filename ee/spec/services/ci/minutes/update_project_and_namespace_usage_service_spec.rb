# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UpdateProjectAndNamespaceUsageService do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:namespace) { project.namespace }

  let(:consumption_minutes) { 120 }
  let(:consumption_seconds) { consumption_minutes * 60 }
  let(:namespace_amount_used) { Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id).amount_used }
  let(:project_amount_used) { Ci::Minutes::ProjectMonthlyUsage.find_or_create_current(project_id: project.id).amount_used }

  describe '#execute' do
    subject { described_class.new(project.id, namespace.id).execute(consumption_minutes) }

    context 'with shared runner' do
      context 'when statistics and usage do not have existing values' do
        it 'updates legacy statistics with consumption seconds' do
          subject

          expect(project.statistics.reload.shared_runners_seconds)
            .to eq(consumption_seconds)

          expect(namespace.namespace_statistics.reload.shared_runners_seconds)
            .to eq(consumption_seconds)
        end

        context 'when project deleted' do
          let(:project) { double(id: non_existing_record_id) }

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

        it 'updates monthly usage with consumption minutes' do
          subject

          expect(namespace_amount_used).to eq(consumption_minutes)
          expect(project_amount_used).to eq(consumption_minutes)
        end

        context 'when feature flag ci_minutes_monthly_tracking is disabled' do
          before do
            stub_feature_flags(ci_minutes_monthly_tracking: false)
          end

          it 'does not update the usage on a monthly basis' do
            subject

            expect(namespace_amount_used).to eq(0)
            expect(project_amount_used).to eq(0)
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
          namespace.create_namespace_statistics(shared_runners_seconds: existing_usage_in_seconds)
          create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: existing_usage_in_minutes)
          create(:ci_project_monthly_usage, project: project, amount_used: existing_usage_in_minutes)
        end

        it 'updates legacy statistics with consumption seconds' do
          subject

          expect(project.statistics.reload.shared_runners_seconds)
            .to eq(existing_usage_in_seconds + consumption_seconds)

          expect(namespace.namespace_statistics.reload.shared_runners_seconds)
            .to eq(existing_usage_in_seconds + consumption_seconds)
        end

        it 'updates monthly usage with consumption minutes' do
          subject

          expect(namespace_amount_used).to eq(existing_usage_in_minutes + consumption_minutes)
          expect(project_amount_used).to eq(existing_usage_in_minutes + consumption_minutes)
        end

        context 'when feature flag ci_minutes_monthly_tracking is disabled' do
          before do
            stub_feature_flags(ci_minutes_monthly_tracking: false)
          end

          it 'does not update usage' do
            subject

            expect(namespace_amount_used).to eq(existing_usage_in_minutes)
            expect(project_amount_used).to eq(existing_usage_in_minutes)
          end
        end
      end
    end
  end
end
