# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Reconciliations::CalculateSeatCountDataService, :saas do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:should_check_namespace_plan) { true }

    before do
      allow_next_instance_of(GitlabSubscriptions::Reconciliations::CheckSeatUsageAlertsEligibilityService) do |service|
        expect(service).to receive(:execute).and_return(alert_user_overage)
      end

      allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(should_check_namespace_plan)
    end

    subject(:execute_service) { described_class.new(namespace: root_ancestor, user: user).execute }

    context 'with no subscription' do
      let(:root_ancestor) { create(:group) }
      let(:alert_user_overage) { true }

      before do
        root_ancestor.add_owner(user)
      end

      it { is_expected.to be nil }
    end

    context 'when conditions are not met' do
      let(:max_seats_used) { 9 }

      before do
        create(
          :gitlab_subscription,
          namespace: root_ancestor,
          plan_code: Plan::ULTIMATE,
          seats: 10,
          max_seats_used: max_seats_used
        )
      end

      context 'when it is not SaaS' do
        let(:alert_user_overage) { true }
        let(:root_ancestor) { create(:group) }
        let(:should_check_namespace_plan) { false }

        before do
          root_ancestor.add_owner(user)
        end

        it { is_expected.to be nil }
      end

      context 'when namespace is not a group' do
        let(:alert_user_overage) { true }
        let(:root_ancestor) { create(:namespace, :with_namespace_settings) }

        it { is_expected.to be nil }
      end

      context 'when the alert was dismissed' do
        let(:alert_user_overage) { true }
        let(:root_ancestor) { create(:group) }

        before do
          allow(user).to receive(:dismissed_callout_for_group?).and_return(true)
          root_ancestor.add_owner(user)
        end

        it { is_expected.to be nil }
      end

      context 'when the user does not have admin rights to the group' do
        let(:alert_user_overage) { true }
        let(:root_ancestor) { create(:group) }

        before do
          root_ancestor.add_developer(user)
        end

        it { is_expected.to be nil }
      end

      context 'when the subscription is not eligible for usage alerts' do
        let(:alert_user_overage) { false }
        let(:root_ancestor) { create(:group) }

        before do
          root_ancestor.add_owner(user)
        end

        it { is_expected.to be nil }
      end

      context 'when max seats used are more than the subscription seats' do
        let(:alert_user_overage) { true }
        let(:max_seats_used) { 11 }
        let(:root_ancestor) { create(:group) }

        before do
          root_ancestor.add_owner(user)
        end

        it { is_expected.to be nil }
      end
    end

    context 'with threshold limits' do
      let_it_be(:alert_user_overage) { true }
      let_it_be(:root_ancestor) { create(:group) }

      before do
        create(
          :gitlab_subscription,
          namespace: root_ancestor,
          plan_code: Plan::ULTIMATE,
          seats: seats,
          max_seats_used: max_seats_used
        )

        root_ancestor.add_owner(user)
      end

      context 'when limits are not met' do
        where(:seats, :max_seats_used) do
          15    | 13
          24    | 20
          35    | 29
          100   | 90
          1000  | 949
        end

        with_them do
          it { is_expected.to be nil }
        end
      end

      context 'when limits are met' do
        where(:seats, :max_seats_used) do
          15    | 14
          24    | 22
          35    | 32
          100   | 93
          1000  | 950
        end

        with_them do
          it {
            is_expected.to eq({
              namespace: root_ancestor,
              remaining_seat_count: [seats - max_seats_used, 0].max,
              seats_in_use: max_seats_used,
              total_seat_count: seats
            })
          }
        end
      end
    end
  end
end
