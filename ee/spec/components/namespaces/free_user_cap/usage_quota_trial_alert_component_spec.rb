# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::UsageQuotaTrialAlertComponent, :saas, :aggregate_failures, type: :component,
  feature_category: :experimentation_conversion do
  let_it_be(:namespace, refind: true) { create(:group, :private) }
  let_it_be(:user, refind: true) { create(:user) }
  let(:content_class) { '_content_class_' }
  let(:trial_ends_on) { Date.parse('2022-06-01') }
  let(:free_user_cap_enabled) { true }
  let!(:gitlab_subscription) do
    create(:gitlab_subscription, :active_trial, :free, namespace: namespace, trial_ends_on: trial_ends_on)
  end

  let(:title) do
    "On 1, Jun, 2022, your trial will end and #{namespace.name} will be limited to " \
      "#{::Namespaces::FreeUserCap.dashboard_limit} members"
  end

  let(:body) do
    "When your trial ends, you'll move to the Free tier, which has a limit of " \
      "#{::Namespaces::FreeUserCap.dashboard_limit} seats. #{::Namespaces::FreeUserCap.dashboard_limit} " \
      'seats will remain active, and members not occupying a seat will have the Over limit ' \
      'status and lose access to this group. To get more seats, upgrade to a paid tier.'
  end

  subject(:component) do
    described_class.new(namespace: namespace, user: user, content_class: content_class)
  end

  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
    stub_ee_application_setting(dashboard_enforcement_limit: 5)
    stub_feature_flags(free_user_cap: free_user_cap_enabled)
    namespace.add_owner(user)
    travel_to(trial_ends_on)
  end

  shared_examples 'does not render the banner' do
    it 'does not have banner content' do
      render_inline(component)

      expect(page).not_to have_selector(".#{content_class}")
      expect(page).not_to have_content(title)
      expect(page).not_to have_content(body)
    end
  end

  context 'when on trial' do
    it 'renders the banner' do
      render_inline(component)

      expect(page).to have_selector(".#{content_class}")
      expect(page).to have_content(title)
      expect(page).to have_content(body)
      expect(page).to have_link('Over limit status', href: described_class::BLOG_URL)
      expect(page).to have_link('upgrade to a paid tier', href: group_billings_path(namespace))
      expect(page).not_to have_css('.gl-alert-actions')

      expect(page).to have_css('.js-user-over-limit-free-plan-alert' \
                               "[data-dismiss-endpoint='#{group_callouts_path}']" \
                               "[data-feature-id='#{described_class::USAGE_QUOTA_TRIAL_ALERT}']" \
                               "[data-group-id='#{namespace.id}']")
    end

    context 'when group is public' do
      before do
        namespace.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      include_examples 'does not render the banner'
    end

    context 'when the free_user_cap feature flag is not enabled' do
      let(:free_user_cap_enabled) { false }

      include_examples 'does not render the banner'
    end
  end

  context 'when not on trial' do
    let!(:gitlab_subscription) { create(:gitlab_subscription, :free, namespace: namespace) }

    include_examples 'does not render the banner'
  end
end
