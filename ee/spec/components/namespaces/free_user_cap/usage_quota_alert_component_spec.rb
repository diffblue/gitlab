# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::UsageQuotaAlertComponent, :saas, :aggregate_failures, type: :component,
  feature_category: :experimentation_conversion do
  let_it_be(:namespace, refind: true) { create(:group, :private) }
  let_it_be(:user, refind: true) { create(:user) }
  let(:content_class) { '_content_class_' }
  let(:free_plan_members_count) { 6 }
  let!(:gitlab_subscription) { create(:gitlab_subscription, :expired, :free, namespace: namespace) }
  let(:title) do
    "Your free group is now limited to #{::Namespaces::FreeUserCap.dashboard_limit} members"
  end

  let(:body) do
    "Your group recently changed to use the Free plan. Free groups are limited to " \
      "#{::Namespaces::FreeUserCap.dashboard_limit} members and " \
      "the remaining members will get a status of over-limit and lose access to the group. You can " \
      "free up space for new members by removing those who no longer need access or toggling them " \
      "to over-limit. To get an unlimited number of members, you can upgrade to a paid tier."
  end

  subject(:component) { described_class.new(namespace: namespace, user: user, content_class: content_class) }

  before do
    namespace.add_owner(user)

    stub_ee_application_setting(dashboard_limit_enabled: true)
    stub_ee_application_setting(dashboard_enforcement_limit: 5)
    allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
  end

  shared_examples 'renders the alert' do
    it 'has content for the alert' do
      render_inline(component)

      expect(page).to have_selector(".#{content_class}")
      expect(page).to have_content(title)
      expect(page).to have_content(body)
      expect(page).to have_link('upgrade', href: group_billings_path(namespace))
      expect(page).not_to have_css('.gl-alert-actions')

      expect(page)
        .to have_css('.js-user-over-limit-free-plan-alert' \
                     "[data-dismiss-endpoint='#{group_callouts_path}']" \
                     "[data-feature-id='#{described_class::FREE_GROUP_LIMITED_ALERT}']" \
                     "[data-group-id='#{namespace.id}']")
    end

    it 'renders all the expected tracking items' do
      render_inline(component)

      expect(page).to have_css('[data-testid="free-group-limited-alert"]' \
                               '[data-track-action="render"]' \
                               '[data-track-property="free_group_limited_usage_quota_banner"]')
      expect(page).to have_css('[data-testid="free-group-limited-dismiss"]' \
                               '[data-track-action="dismiss_banner"]' \
                               '[data-track-property="free_group_limited_usage_quota_banner"]')
      expect(page).to have_css('[data-track-action="click_link"]' \
                               '[data-track-label="upgrade"]' \
                               '[data-track-property="free_group_limited_usage_quota_banner"]')
    end
  end

  shared_examples 'does not render the alert' do
    it 'does not have the title' do
      render_inline(component)

      expect(page).not_to have_content(title)
    end
  end

  context 'when under the limit' do
    let(:free_plan_members_count) { 5 }

    it_behaves_like 'does not render the alert'
  end

  context 'when over the limit' do
    context 'when paid subscription is expired' do
      let!(:gitlab_subscription) do
        create(:gitlab_subscription, :expired, namespace: namespace)
      end

      it_behaves_like 'does not render the alert'

      context 'when it is a trial' do
        let!(:gitlab_subscription) do
          create(:gitlab_subscription, :expired, :active_trial, namespace: namespace)
        end

        it_behaves_like 'does not render the alert'
      end
    end

    context 'when free subscription' do
      context 'when subscription is expired' do
        it_behaves_like 'renders the alert'
      end

      context 'when trial is expired' do
        let!(:gitlab_subscription) { create(:gitlab_subscription, :expired_trial, :free, namespace: namespace) }

        it_behaves_like 'renders the alert'
      end

      context 'when trial is active' do
        let!(:gitlab_subscription) { create(:gitlab_subscription, :active_trial, :free, namespace: namespace) }

        it_behaves_like 'does not render the alert'
      end

      context 'when group is public' do
        before do
          namespace.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it_behaves_like 'does not render the alert'
      end
    end
  end
end
