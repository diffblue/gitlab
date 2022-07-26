# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::PersonalPreviewAlertComponent, :saas, :aggregate_failures, type: :component do
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:namespace) { user.namespace }
  let_it_be(:content_class) { '_content_class_' }

  let(:preview_free_user_cap_over?) { true }
  let(:title) { 'From October 19, 2022, you can have a maximum' }

  subject(:component) { described_class.new(namespace: namespace, user: user, content_class: content_class) }

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Preview) do |preview_free_user_cap|
      allow(preview_free_user_cap).to receive(:over_limit?).and_return(preview_free_user_cap_over?)
    end
  end

  context 'when over limit' do
    it 'has content for the preview alert' do
      render_inline(component)

      expect(rendered_component).to have_selector(".#{content_class}")
      expect(rendered_component).to have_content(title)
      expect(rendered_component).to have_link('View all personal projects', href: user_projects_path(user.username))
      expect(rendered_component).to have_link('Over limit status', href: described_class::BLOG_URL)
      expect(rendered_component).to have_link('move your projects to a group')
      expect(rendered_component)
        .to have_css("[data-testid='user-over-limit-free-plan-alert']" \
                         "[data-dismiss-endpoint='#{callouts_path}']" \
                         "[data-feature-id='#{described_class::PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT}']")
      expect(rendered_component).not_to have_css('[data-testid="user-over-limit-secondary-cta"]')
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
                                                 '[data-track-label="view_personal_projects"]')
    end

    context 'when alert has been dismissed' do
      context 'with a fresh dismissal' do
        before do
          create(:callout,
                 user: user,
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
          create(:callout,
                 user: user,
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

  context 'when user is not authorized to see alert' do
    let_it_be(:user) { create(:user) }

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
