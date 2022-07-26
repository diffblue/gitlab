# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::PreviewAlertComponent, :saas, :aggregate_failures, type: :component do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:content_class) { '_content_class_' }

  let(:preview_free_user_cap_over?) { true }
  let(:title) { 'From October 19, 2022, free groups will be limited' }

  subject(:component) { described_class.new(namespace: namespace, user: user, content_class: content_class) }

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Preview) do |preview_free_user_cap|
      allow(preview_free_user_cap).to receive(:over_limit?).and_return(preview_free_user_cap_over?)
    end
  end

  context 'when user is authorized to see alert' do
    before do
      namespace.add_owner(user)
    end

    context 'when over limit' do
      it 'has content for the preview alert' do
        render_inline(component)

        expect(rendered_component).to have_selector(".#{content_class}")
        expect(rendered_component).to have_content(title)
        expect(rendered_component).to have_link('Manage members', href: group_usage_quotas_path(namespace))
        expect(rendered_component).to have_link('Explore paid plans', href: group_billings_path(namespace))
        expect(rendered_component).to have_link('Over limit status', href: described_class::BLOG_URL)
        expect(rendered_component)
          .to have_css("[data-testid='user-over-limit-free-plan-alert']" \
                         "[data-dismiss-endpoint='#{group_callouts_path}']" \
                         "[data-feature-id='#{described_class::PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT}']" \
                         "[data-group-id='#{namespace.id}']")
      end

      it 'renders all the expected tracking items' do
        render_inline(component)

        expect(rendered_component).to have_css('.js-user-over-limit-free-plan-alert[data-track-action="render"]' \
                                                 '[data-track-label="user_limit_banner"]')
        expect(rendered_component).to have_css('[data-testid="user-over-limit-free-plan-dismiss"]' \
                                                 '[data-track-action="dismiss_banner"]' \
                                                 '[data-track-label="user_limit_banner"]')
        expect(rendered_component).to have_css('[data-testid="user-over-limit-primary-cta"]' \
                                                 '[data-track-action="click_button"]' \
                                                 '[data-track-label="manage_members"]')
        expect(rendered_component).to have_css('[data-testid="user-over-limit-secondary-cta"]' \
                                                 '[data-track-action="click_button"]' \
                                                 '[data-track-label="explore_paid_plans"]')
      end

      context 'when alert has been dismissed' do
        context 'with a fresh dismissal' do
          before do
            create(:group_callout,
                   user: user,
                   group: namespace,
                   feature_name: described_class::PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT,
                   dismissed_at: Time.now)
          end

          it 'does not render the alert' do
            render_inline(component)

            expect(rendered_component).not_to have_content(title)
          end
        end

        context 'when alert dismissal has aged out' do
          before do
            create(:group_callout,
                   user: user,
                   group: namespace,
                   feature_name: described_class::PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT,
                   dismissed_at: described_class::IGNORE_DISMISSAL_EARLIER_THAN - 1.day)
          end

          it 'renders the alert' do
            render_inline(component)

            expect(rendered_component).to have_content(title)
          end
        end
      end
    end

    context 'when not over the limit' do
      let(:preview_free_user_cap_over?) { false }

      it 'does not render the alert' do
        render_inline(component)

        expect(rendered_component).not_to have_content(title)
      end
    end
  end

  context 'when user is not authorized to see alert' do
    it 'does not render the alert' do
      render_inline(component)

      expect(rendered_component).not_to have_content(title)
    end
  end

  context 'when user does not exist' do
    let_it_be(:user) { nil }

    it 'does not render the alert' do
      render_inline(component)

      expect(rendered_component).not_to have_content(title)
    end
  end
end
