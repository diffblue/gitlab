# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::BatchResetService, feature_category: :continuous_integration do
  include ::Ci::MinutesHelpers

  let(:service) { described_class.new }

  describe '#execute!' do
    subject { service.execute!(ids_range: ids_range, batch_size: 3) }

    def create_namespace_with_project(seconds_used, monthly_minutes_limit = nil)
      namespace = create(:namespace,
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

      let_it_be(:project_namespace) { create(:project_namespace) }
      let_it_be_with_reload(:namespace_1) { create_namespace_with_project(2_020.minutes, nil) }
      let_it_be_with_reload(:namespace_2) { create_namespace_with_project(2_020.minutes, 2_000) }
      let_it_be_with_reload(:namespace_3) { create_namespace_with_project(2_020.minutes, 2_000) }
      let_it_be_with_reload(:namespace_4) { create_namespace_with_project(1_000.minutes, nil) }
      let_it_be_with_reload(:namespace_5) { create_namespace_with_project(1_000.minutes, 2_000) }
      let_it_be_with_reload(:namespace_6) { create_namespace_with_project(1_000.minutes, 0) }

      let(:ids_range) { (project_namespace.id..namespace_5.id) }
      let(:namespaces_exceeding_minutes) { [namespace_1, namespace_2, namespace_3] }

      it 'resets minutes in batches for the given range and ignores project namespaces' do
        expect(service).to receive(:reset_ci_minutes!).with(match_array([namespace_1, namespace_2, namespace_3]))
        expect(service).to receive(:reset_ci_minutes!).with(match_array([namespace_4, namespace_5]))

        subject
      end

      it 'resets CI minutes but does not recalculate purchased minutes for the namespace exceeding the monthly minutes' do
        subject

        namespaces_exceeding_minutes.each do |namespace|
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

      context 'when an ActiveRecordError is raised' do
        before do
          expect(Namespace).to receive(:transaction).once.ordered.and_raise(ActiveRecord::ActiveRecordError, 'something went wrong')
          expect(Namespace).to receive(:transaction).once.ordered.and_call_original
        end

        it 'continues its progress and raises exception at the end' do
          expect(service).to receive(:reset_ci_minutes!).with(match_array([namespace_1, namespace_2, namespace_3])).and_call_original
          expect(service).to receive(:reset_ci_minutes!).with(match_array([namespace_4, namespace_5])).and_call_original

          expect { subject }
            .to raise_error(described_class::BatchNotResetError) do |error|
              expect(error.message).to eq('Some namespace shared runner minutes were not reset')
              expect(error.sentry_extra_data[:failed_batches]).to contain_exactly(
                {
                  count: 3,
                  first_namespace_id: namespace_1.id,
                  last_namespace_id: namespace_3.id,
                  error_message: 'something went wrong',
                  error_backtrace: kind_of(Array)
                }
              )
            end
        end
      end
    end
  end
end
