# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::EnforcementAtLimitAlertComponent, :saas, :aggregate_failures, type: :component,
  feature_category: :experimentation_conversion do
  let(:namespace) { build_stubbed(:group) }
  let(:content_class) { '_content_class_' }
  let(:user) { build_stubbed(:user) }
  let(:free_user_cap_at_limit?) { true }
  let(:owner_access?) { true }
  let(:title) do
    "Your top-level group #{namespace.name} has reached the " \
      "#{::Namespaces::FreeUserCap.dashboard_limit} user limit"
  end

  subject(:component) do
    described_class.new(namespace: namespace, user: user, content_class: content_class)
  end

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Enforcement) do |free_user_cap|
      allow(free_user_cap).to receive(:at_limit?).and_return(free_user_cap_at_limit?)
    end

    allow(Ability).to receive(:allowed?)
                  .with(user, :owner_access, namespace)
                  .and_return(owner_access?)
  end

  context 'when user is authorized to see alert' do
    context 'when at the limit' do
      it 'has content for the alert' do
        render_inline(component)

        expect(page).to have_content(title)
        expect(page).to have_css('.gl-alert-actions')
        expect(page).to have_link('Manage members', href: group_usage_quotas_path(namespace))

        expect(page).to have_link(
          'Explore paid plans',
          href: group_billings_path(namespace, source: 'user-limit-alert-enforcement')
        )

        expect(page).to have_css(".gl-overflow-auto.#{content_class}")

        expect(page)
          .to have_css("[data-testid='user-over-limit-free-plan-alert']" \
                       "[data-dismiss-endpoint='#{group_callouts_path}']" \
                       "[data-feature-id='#{described_class::ENFORCEMENT_AT_LIMIT_ALERT}']" \
                       "[data-group-id='#{namespace.id}']")
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

      context 'when alert has been dismissed' do
        before do
          allow(user).to receive(:dismissed_callout_for_group?).with(
            feature_name: described_class::ENFORCEMENT_AT_LIMIT_ALERT,
            group: namespace,
            ignore_dismissal_earlier_than: nil
          ).and_return(true)
        end

        it 'does not render the alert' do
          render_inline(component)

          expect(page).not_to have_content(title)
        end
      end
    end

    context 'when limit has not been reached' do
      let(:free_user_cap_at_limit?) { false }

      it 'does not render the alert' do
        render_inline(component)

        expect(page).not_to have_content(title)
      end
    end
  end

  context 'when user is not authorized to see alert' do
    let(:owner_access?) { false }

    it 'does not render the alert' do
      render_inline(component)

      expect(page).not_to have_content(title)
    end
  end

  context 'when user does not exist' do
    let(:user) { nil }

    it 'does not render the alert' do
      render_inline(component)

      expect(page).not_to have_content(title)
    end
  end
end
