# frozen_string_literal: true

RSpec.shared_examples 'returning the right value for free_user_cap_reached?' do
  context 'when free user cap feature is not applied' do
    before do
      allow(group).to receive(:apply_free_user_cap?).and_return(false)
    end

    it { is_expected.to be_falsey }
  end

  context 'when free user cap feature is applied' do
    before do
      allow(group).to receive(:apply_free_user_cap?).and_return(true)
    end

    context 'when the :saas_user_caps feature flag is not enabled' do
      it { is_expected.to be_falsey }
    end

    context 'when the :free_user_cap feature flag is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
        allow(root_group).to receive(:apply_free_user_cap?).and_return(true)
        allow(root_group).to receive(:has_free_or_no_subscription?).and_return(free_plan)
      end

      let(:free_plan) { false }

      context 'when no free user cap has been set to that root ancestor' do
        it { is_expected.to be_falsey }
      end

      context 'when a free user cap has been set to that root ancestor' do
        let(:free_plan) { true }

        before do
          allow(root_group).to receive(:free_plan_members_count).and_return(free_plan_members_count)
          allow(group).to receive(:root_ancestor).and_return(root_group)
        end

        context 'when the free cap is higher than the number of billable members' do
          let(:free_plan_members_count) { 3 }

          it { is_expected.to be_falsey }
        end

        context 'when the free cap is the same as the number of billable members' do
          let(:free_plan_members_count) { ::Plan::FREE_USER_LIMIT }

          it { is_expected.to be_truthy }
        end

        context 'when the free cap is lower than the number of billable members' do
          let(:free_plan_members_count) { 6 }

          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
