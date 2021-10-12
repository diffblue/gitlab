# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::BatchResetService do
  include ::Ci::MinutesHelpers

  let(:service) { described_class.new }

  describe '#execute!' do
    let(:ids_range) { nil }

    subject { service.execute!(ids_range: ids_range, batch_size: 3) }

    def create_namespace_with_project(id, seconds_used, monthly_minutes_limit = nil)
      namespace = create(:namespace,
        id: id,
        shared_runners_minutes_limit: monthly_minutes_limit, # when `nil` it inherits the global limit
        extra_shared_runners_minutes_limit: 50,
        last_ci_minutes_notification_at: Time.current,
        last_ci_minutes_usage_notification_level: 30)

      set_ci_minutes_used(namespace, seconds_used.to_f / 60)

      create(:project, namespace: namespace).tap do |project|
        create(:project_statistics,
          project: project,
          namespace: namespace,
          shared_runners_seconds: seconds_used)
      end

      namespace
    end

    context 'when global shared_runners_minutes is enabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes).and_return(2_000)
      end

      let!(:namespace_1) { create_namespace_with_project(1, 2_020.minutes, nil) }
      let!(:namespace_2) { create_namespace_with_project(2, 2_020.minutes, 2_000) }
      let!(:namespace_3) { create_namespace_with_project(3, 2_020.minutes, 2_000) }
      let!(:namespace_4) { create_namespace_with_project(4, 1_000.minutes, nil) }
      let!(:namespace_5) { create_namespace_with_project(5, 1_000.minutes, 2_000) }
      let!(:namespace_6) { create_namespace_with_project(6, 1_000.minutes, 0) }

      context 'when ID range is provided' do
        let(:ids_range) { (1..5) }
        let(:namespaces_exceeding_minutes) { [namespace_1, namespace_2, namespace_3] }
        let(:namespaces_not_exceeding_minutes) { [namespace_4, namespace_5] }

        it 'resets minutes in batches for the given range' do
          expect(service).to receive(:reset_ci_minutes!).with([namespace_1, namespace_2, namespace_3])
          expect(service).to receive(:reset_ci_minutes!).with([namespace_4, namespace_5])

          subject
        end

        it 'resets CI minutes and recalculates purchased minutes for the namespace exceeding the monthly minutes' do
          subject

          namespaces_exceeding_minutes.each do |namespace|
            namespace.reset

            expect(namespace.extra_shared_runners_minutes_limit).to eq 30
            expect(namespace.namespace_statistics.shared_runners_seconds).to eq 0
            expect(namespace.namespace_statistics.shared_runners_seconds_last_reset).to be_present
            expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds).to eq 0
            expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds_last_reset).to be_present
            expect(namespace.last_ci_minutes_notification_at).to be_nil
            expect(namespace.last_ci_minutes_usage_notification_level).to be_nil
          end
        end

        it 'resets CI minutes but does not recalculate purchased minutes for the namespace not exceeding the monthly minutes' do
          subject

          namespaces_not_exceeding_minutes.each do |namespace|
            namespace.reset

            expect(namespace.extra_shared_runners_minutes_limit).to eq 50
            expect(namespace.namespace_statistics.shared_runners_seconds).to eq 0
            expect(namespace.namespace_statistics.shared_runners_seconds_last_reset).to be_present
            expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds).to eq 0
            expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds_last_reset).to be_present
            expect(namespace.last_ci_minutes_notification_at).to be_nil
            expect(namespace.last_ci_minutes_usage_notification_level).to be_nil
          end
        end
      end

      context 'when ID range is not provided' do
        let(:ids_range) { nil }

        it 'resets minutes in batches for all namespaces' do
          expect(service).to receive(:reset_ci_minutes!).with([namespace_1, namespace_2, namespace_3])
          expect(service).to receive(:reset_ci_minutes!).with([namespace_4, namespace_5, namespace_6])

          subject
        end

        it 'resets CI minutes and does not recalculate purchased minutes for the namespace having unlimited monthly minutes' do
          subject

          namespace_6.reset

          expect(namespace_6.extra_shared_runners_minutes_limit).to eq 50
          expect(namespace_6.namespace_statistics.shared_runners_seconds).to eq 0
          expect(namespace_6.namespace_statistics.shared_runners_seconds_last_reset).to be_present
          expect(ProjectStatistics.find_by(namespace: namespace_6).shared_runners_seconds).to eq 0
          expect(ProjectStatistics.find_by(namespace: namespace_6).shared_runners_seconds_last_reset).to be_present
          expect(namespace_6.last_ci_minutes_notification_at).to be_nil
          expect(namespace_6.last_ci_minutes_usage_notification_level).to be_nil
        end
      end

      context 'when an ActiveRecordError is raised' do
        let(:ids_range) { nil }

        before do
          expect(Namespace).to receive(:transaction).once.ordered.and_raise(ActiveRecord::ActiveRecordError, 'something went wrong')
          expect(Namespace).to receive(:transaction).once.ordered.and_call_original
        end

        it 'continues its progress and raises exception at the end' do
          expect(service).to receive(:reset_ci_minutes!).with([namespace_1, namespace_2, namespace_3]).and_call_original
          expect(service).to receive(:reset_ci_minutes!).with([namespace_4, namespace_5, namespace_6]).and_call_original

          expect { subject }
            .to raise_error(described_class::BatchNotResetError) do |error|
              expect(error.message).to eq('Some namespace shared runner minutes were not reset')
              expect(error.sentry_extra_data[:failed_batches]).to contain_exactly(
                {
                  count: 3,
                  first_namespace_id: 1,
                  last_namespace_id: 3,
                  error_message: 'something went wrong',
                  error_backtrace: kind_of(Array)
                }
              )
            end
        end
      end
    end

    context 'when global shared_runners_minutes setting is nil and namespaces have no limits' do
      using RSpec::Parameterized::TableSyntax

      where(:global_limit, :namespace_limit) do
        nil | 0
        nil | nil
        0   | 0
        0   | nil
      end

      with_them do
        let!(:namespace) { create_namespace_with_project(1, 100.minutes, namespace_limit) }

        before do
          allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes).and_return(global_limit)
        end

        it 'does not recalculate purchased minutes for any namespaces' do
          subject

          namespace.reset
          expect(namespace.extra_shared_runners_minutes_limit).to eq 50
        end
      end
    end
  end
end
