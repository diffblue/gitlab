# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::NotificationAlertComponent, :saas, :aggregate_failures, type: :component, feature_category: :experimentation_conversion do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user, refind: true) { create(:user) }
  let(:content_class) { '_content_class_' }
  let(:notification_free_user_cap_over?) { true }
  let(:title) do
    "Your top-level group #{namespace.name} will move to a read-only state soon"
  end

  subject(:component) { described_class.new(namespace: namespace, user: user, content_class: content_class) }

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Notification) do |notification_free_user_cap|
      allow(notification_free_user_cap).to receive(:over_limit?).and_return(notification_free_user_cap_over?)
    end
  end

  context 'when user is authorized to see alert' do
    before do
      namespace.add_owner(user)
    end

    context 'when over limit' do
      it 'has content for the notification alert' do
        promotion = 'GitLab is offering a'

        render_inline(component)

        expect(page).to have_css(".gl-overflow-auto.#{content_class}")
        expect(page).to have_content(title)
        expect(page).to have_link('read-only', href: help_page_path('user/read_only_namespaces'))
        expect(page).to have_content(promotion)
        expect(page).to have_link('one-time discount', href: described_class::PROMOTION_URL)
        expect(page).to have_link('Manage members', href: group_usage_quotas_path(namespace))

        expect(page).to have_link(
          'Explore paid plans',
          href: group_billings_path(namespace, source: 'user-limit-alert-enforcement')
        )

        expect(page)
          .to have_css('[data-testid="user-over-limit-free-plan-alert"]')
      end

      it 'renders all the expected tracking items' do
        render_inline(component)

        expect(page).to have_css('.js-user-over-limit-free-plan-alert[data-track-action="render"]' \
                                 '[data-track-label="user_limit_banner"]')
        expect(page).to have_css('[data-testid="user-over-limit-primary-cta"]' \
                                 '[data-track-action="click_button"]' \
                                 '[data-track-label="manage_members"]')
        expect(page).to have_css('[data-testid="user-over-limit-secondary-cta"]' \
                                 '[data-track-action="click_button"]' \
                                 '[data-track-label="explore_paid_plans"]')
      end
    end

    context 'when not over the limit' do
      let(:notification_free_user_cap_over?) { false }

      it 'does not render the alert' do
        render_inline(component)

        expect(page).not_to have_content(title)
      end
    end
  end

  context 'when user is not authorized to see alert' do
    it 'does not render the alert' do
      render_inline(component)

      expect(page).not_to have_content(title)
    end
  end

  context 'when user does not exist' do
    let_it_be(:user) { nil }

    it 'does not render the alert' do
      render_inline(component)

      expect(page).not_to have_content(title)
    end
  end
end
