# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Abuse::NewAbuseReportWorker, :saas, feature_category: :instance_resiliency do
  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:abuse_report) { create(:abuse_report, user: user, reporter: reporter) }
  let_it_be(:job_args) { [abuse_report.id] }
  let_it_be(:user_custom_attributes) do
    {
      user_id: user.id,
      key: UserCustomAttribute::AUTO_BANNED_BY_ABUSE_REPORT_ID,
      value: abuse_report.id
    }
  end

  shared_examples 'bans user' do
    it 'bans the user' do
      expect(user).to receive(:ban!).and_call_original
      expect(UserCustomAttribute).to receive(:upsert_custom_attributes).with([user_custom_attributes]).and_call_original
      worker.perform(*job_args)

      expect(user).to be_banned
      expect(user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_ABUSE_REPORT_ID).first).not_to be_nil
    end
  end

  shared_examples 'does not ban user' do
    it 'does not ban the user' do
      expect(user).not_to receive(:ban!)
      expect(UserCustomAttribute).not_to receive(:upsert_custom_attributes)
      worker.perform(*job_args)

      expect(user).not_to be_banned
    end
  end

  it_behaves_like 'an idempotent worker' do
    subject(:worker) { described_class.new }

    context 'when reporter is a gitlab employee' do
      before do
        allow(reporter).to receive(:gitlab_employee?).and_return(true)
        allow(user).to receive(:human?).and_return(true)
        allow(user).to receive(:active?).and_return(true)
        allow(AbuseReport).to receive(:find_by_id).and_return(abuse_report)
      end

      context 'when the user is a member of a namespace with a paid plan trial subscription' do
        let_it_be(:trial_group) { create(:group_with_plan, plan: :ultimate_plan, trial_ends_on: 1.day.from_now) }

        before do
          trial_group.add_reporter(user)
        end

        it_behaves_like 'bans user'
      end

      context 'when the user is a member of a namespace with a paid plan subscription' do
        let_it_be(:paid_group) { create(:group_with_plan, plan: :ultimate_plan) }

        before do
          paid_group.add_reporter(user)
        end

        it_behaves_like 'does not ban user'
      end

      context 'when the user is on a free plan' do
        context 'when the user is human' do
          it_behaves_like 'bans user'
        end

        context 'when the user is not human' do
          before do
            allow(user).to receive(:human?).and_return(false)
          end

          it_behaves_like 'does not ban user'
        end
      end

      context 'when the user is not active' do
        before do
          allow(user).to receive(:active?).and_return(false)
        end

        it_behaves_like 'does not ban user'
      end

      context 'when the user is not found' do
        before do
          allow(abuse_report).to receive(:user).and_return(nil)
        end

        it 'does not start a transaction' do
          expect(described_class).not_to receive(:bannable_user?)

          worker.perform(*job_args)
        end
      end

      context 'when the user is a gitlab employee' do
        before do
          allow(user).to receive(:gitlab_employee?).and_return(true)
        end

        it_behaves_like 'does not ban user'
      end

      context 'when the user age is greater than 7 days' do
        before do
          user.update_attribute(:created_at, 8.days.ago)
        end

        it_behaves_like 'does not ban user'
      end

      context 'when user owns namespaces with more than five members' do
        let_it_be(:group) { create(:group) }

        before do
          group.add_owner(user)
          5.times { group.add_guest(create(:user)) }
        end

        it_behaves_like 'does not ban user'
      end
    end

    context 'when reporter is not a gitlab employee' do
      it_behaves_like 'does not ban user'
    end

    context 'when the abuse report is not found' do
      before do
        allow(AbuseReport).to receive(:find_by_id).and_return(nil)
      end

      it 'returns early' do
        expect(abuse_report).not_to receive(:reporter)

        worker.perform(*job_args)
      end
    end

    context 'when there is an error executing ban' do
      before do
        allow(user).to receive(:ban!).and_raise(StateMachines::InvalidTransition)
      end

      it 'does not emit an application log' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        worker.perform(*job_args)
      end
    end
  end
end
