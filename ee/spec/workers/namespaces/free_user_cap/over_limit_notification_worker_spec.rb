# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_activation used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::OverLimitNotificationWorker, feature_category: :experimentation_activation,
  type: :worker,
  ee: true do
  let(:frozen_time) { Time.zone.parse "2022-09-22T00:00+0" }

  around do |example|
    travel_to(frozen_time) { example.run }
  end

  describe '#perform', :saas do
    subject(:worker) { described_class.new.perform }

    let(:group) { create :group_with_plan, :private, plan: :free_plan }
    let(:owner) { create :owner }

    before do
      group.add_owner owner
      group.namespace_details.update! next_over_limit_check_at: 2.days.ago
    end

    context 'when on gitlab.com', :saas do
      before do
        stub_ee_application_setting should_check_namespace_plan: true
        stub_ee_application_setting dashboard_limit_enabled: true
      end

      it 'runs notifiy service and marks next check for group' do
        expect(::Namespaces::FreeUserCap::NotifyOverLimitGroupsService).to receive(:execute)

        next_check_time = frozen_time + described_class::SCHEDULE_BUFFER_IN_HOURS.hours

        expect { subject }.to change { group.reload.namespace_details.next_over_limit_check_at }.to(next_check_time)
      end
    end

    context 'with feature flags enabled/disabled' do
      where(
        limit_enabled: [true, false, false],
        free_user_cap_over_user_limit_mails: [false, true, false]
      )

      before do
        stub_ee_application_setting dashboard_limit_enabled: limit_enabled
        stub_ee_application_setting should_check_namespace_plan: true
        stub_feature_flags free_user_cap_over_user_limit_mails: free_user_cap_over_user_limit_mails
      end

      with_them do
        it 'triggers mail the namespace owners', :aggregate_failures do
          if limit_enabled && free_user_cap_over_user_limit_mails
            expect(::Namespaces::FreeUserCap::NotifyOverLimitGroupsService).to receive(:execute)
            expect(described_class.new.max_running_jobs).to eq(5)
          else
            expect(::Namespaces::FreeUserCap::NotifyOverLimitGroupsService).not_to receive(:execute)
            expect(described_class.new.max_running_jobs).to eq(0)
          end

          subject
        end
      end
    end
  end
end
