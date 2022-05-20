# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::PersonalAlertComponent, :saas, :aggregate_failures, type: :component do
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:namespace) { user.namespace }
  let_it_be(:content_class) { '_content_class_' }

  let(:free_user_cap_reached_limit?) { true }
  let(:title) { "You've reached your #{::Namespaces::FreeUserCap::FREE_USER_LIMIT} member limit" }

  subject(:component) { described_class.new(namespace: namespace, user: user, content_class: content_class) }

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Standard) do |free_user_cap|
      allow(free_user_cap).to receive(:reached_limit?).and_return(free_user_cap_reached_limit?)
    end
  end

  context 'when limit has been reached' do
    it 'has content for the alert' do
      render_inline(component)

      expect(rendered_component).to have_selector(".#{content_class}")
      expect(rendered_component).to have_content(title)
      expect(rendered_component).to have_link('View all personal projects', href: user_projects_path(user.username))
      expect(rendered_component).to have_link('move your projects to a group')
      expect(rendered_component)
        .to have_css("[data-testid='user-over-limit-free-plan-alert']" \
                         "[data-dismiss-endpoint='#{callouts_path}']" \
                         "[data-feature-id='#{described_class::USER_REACHED_LIMIT_FREE_PLAN_ALERT}']")
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
          create(:callout, user: user, feature_name: described_class::USER_REACHED_LIMIT_FREE_PLAN_ALERT)
        end

        it 'does not render the alert' do
          render_inline(component)

          expect(rendered_component).not_to have_content(title)
        end
      end
    end
  end

  context 'when limit has not been reached' do
    let(:free_user_cap_reached_limit?) { false }

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
