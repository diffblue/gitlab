# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_activation used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::NotificationClearingWorker, :saas, type: :worker, feature_category: :experimentation_activation do
  describe '#perform' do
    let(:frozen_time) { Time.zone.parse '1984-09-04T00:00+0' }
    let(:namespace) { create :group_with_plan, :private, plan: :free_plan }
    let(:details) { namespace.namespace_details }

    subject(:worker) { described_class.new }

    around do |example|
      travel_to(frozen_time) { example.run }
    end

    context 'with a namespace that is due for a check' do
      it 'calls clear flag service and reschedules next check' do
        details.update! free_user_cap_over_limit_notified_at: (frozen_time - 42.days)

        success_result = ServiceResponse.new(status: :success, message: 'test')
        expect(::Namespaces::FreeUserCap::ClearOverLimitNotificationService)
          .to receive(:execute).with(root_namespace: namespace).and_return(success_result)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:status, :success)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:message, 'test')

        worker.perform

        expect(details.reload.next_over_limit_check_at).to eq(frozen_time + described_class::SCHEDULING_BUFFER.hours)
      end
    end

    context 'with no namespaces due for check' do
      it 'does not call service and keeps next_over_limit_check_at untouched' do
        check_at_time = frozen_time - 48.hours
        details.update!(
          next_over_limit_check_at: check_at_time,
          free_user_cap_over_limit_notified_at: (frozen_time - 42.minutes)
        )
        create :group_with_plan, :private, plan: :free_plan

        expect(::Namespaces::FreeUserCap::ClearOverLimitNotificationService).not_to receive(:execute)

        worker.perform

        expect(details.reload.next_over_limit_check_at).to eq(check_at_time)
      end
    end
  end
end
