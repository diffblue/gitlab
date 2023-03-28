# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_activation used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::OverLimitNotificationWorker, :saas, feature_category: :experimentation_activation, type: :worker do
  using RSpec::Parameterized::TableSyntax

  describe '#perform' do
    let(:frozen_time) { Time.zone.parse '2022-09-22T00:00+0' }
    let_it_be(:namespace) do
      create(:group_with_plan, :private, plan: :free_plan).tap do |record|
        record.add_owner(create(:user))
      end
    end

    around do |example|
      travel_to(frozen_time) { example.run }
    end

    subject(:worker) { described_class.new.perform }

    before do
      namespace.namespace_details.update! next_over_limit_check_at: 2.days.ago
      stub_ee_application_setting should_check_namespace_plan: true
    end

    it 'runs notify service and marks next check for the namespace' do
      stub_ee_application_setting dashboard_limit_enabled: true

      expect(::Namespaces::FreeUserCap::NotifyOverLimitService).to receive(:execute).with(root_namespace: namespace)

      next_check_time = frozen_time + described_class::SCHEDULE_BUFFER_IN_HOURS.hours

      expect { worker }.to change { namespace.reload.namespace_details.next_over_limit_check_at }.to(next_check_time)
    end

    context 'with feature flags enabled/disabled' do
      where(:limit_enabled, :free_user_cap_over_user_limit_mails, :call_service, :job_count) do
        true  | true  | 1 | described_class::MAX_RUNNING_JOBS
        true  | false | 0 | 0
        false | true  | 0 | 0
        false | false | 0 | 0
      end

      with_them do
        it 'triggers the namespace owners mail', :aggregate_failures do
          stub_ee_application_setting dashboard_limit_enabled: limit_enabled
          stub_feature_flags free_user_cap_over_user_limit_mails: free_user_cap_over_user_limit_mails

          expect(::Namespaces::FreeUserCap::NotifyOverLimitService).to receive(:execute).exactly(call_service).times
          expect(described_class.new.max_running_jobs).to eq(job_count)

          worker
        end
      end
    end
  end
end
