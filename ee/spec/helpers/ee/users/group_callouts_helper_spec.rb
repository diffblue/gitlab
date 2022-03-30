# frozen_string_literal: true

require "spec_helper"

RSpec.describe EE::Users::GroupCalloutsHelper do
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.show_user_over_limit_free_plan_alert?' do
    let(:preview_free_user_cap_over?) { true }

    subject { helper.show_user_over_limit_free_plan_alert?(group) }

    before do
      allow(group).to receive(:preview_free_user_cap_over?).and_return(preview_free_user_cap_over?)
    end

    context 'when it is a group namespace' do
      context 'when user has the owner_access ability for the group' do
        before do
          group.add_owner(user)
        end

        context 'when the invite_members_banner has not been dismissed' do
          it { is_expected.to eq(true) }

          context 'when preview_free_user_cap_over? is false' do
            let(:preview_free_user_cap_over?) { false }

            it { is_expected.to eq(false) }
          end
        end

        context 'when the preview_user_over_limit_free_plan_alert has been dismissed' do
          before do
            create(:group_callout,
                   user: user,
                   group: group,
                   feature_name: described_class::PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT,
                   dismissed_at: Time.now)
          end

          it { is_expected.to eq(false) }
        end

        context 'when the preview_user_over_limit_free_plan_alert dismissal is no longer valid after 7 days' do
          before do
            create(:group_callout,
                   user: user,
                   group: group,
                   feature_name: described_class::PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT,
                   dismissed_at: 15.days.ago)
          end

          it { is_expected.to eq(true) }
        end
      end

      context 'when user does not have owner_access ability for the group' do
        it { is_expected.to eq(false) }
      end
    end

    context 'when it is a user_namespace' do
      let_it_be(:group) { user.namespace }

      it { is_expected.to eq(false) }
    end
  end
end
