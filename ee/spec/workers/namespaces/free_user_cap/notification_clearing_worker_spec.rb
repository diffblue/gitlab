# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_activation used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::NotificationClearingWorker,
  type: :worker,
  feature_category: :experimentation_activation do
  let(:worker) { described_class.new }

  let(:frozen_time) { Time.zone.parse "1984-09-04T00:00+0" }
  let(:group) { create :group_with_plan, :private, plan: :free_plan }
  let(:details) { group.namespace_details }

  around do |example|
    travel_to(frozen_time) { example.run }
  end

  describe '#perform', :saas do
    subject(:worker) { described_class.new }

    context 'with a group that is due for a check' do
      it 'calls clear flag service and reschedules next check' do
        details.update! free_user_cap_over_limit_notified_at: (frozen_time - 42.days)

        expect(::Namespaces::FreeUserCap::ClearOverLimitGroupNotificationService).to receive(:execute)
          .and_return(ServiceResponse.new(status: :success, message: 'test'))
        expect(worker).to receive(:log_extra_metadata_on_done).with(:status, :success)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:message, 'test')

        worker.perform

        expect(details.reload.next_over_limit_check_at).to eq(Time.zone.parse("1984-09-05T00:00+0"))
      end
    end

    context 'with no groups due for check' do
      it 'does not call service and keeps next_over_limit_check_at untouched' do
        details.update!(
          next_over_limit_check_at: (frozen_time - 48.hours),
          free_user_cap_over_limit_notified_at: (frozen_time - 42.minutes)
        )
        create :group_with_plan, :private, plan: :free_plan

        expect(::Namespaces::FreeUserCap::ClearOverLimitGroupNotificationService).not_to receive(:execute)

        worker.perform

        expect(details.reload.next_over_limit_check_at).to eq(Time.zone.parse("1984-09-02T00:00+0"))
      end
    end
  end
end
