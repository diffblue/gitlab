# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::NonOwnerNotificationAlertComponent, :saas, :aggregate_failures, type: :component, feature_category: :experimentation_conversion do
  let_it_be(:namespace) { create(:group, :private) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:user, refind: true) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let(:content_class) { '_content_class_' }
  let(:notification_free_user_cap_over?) { true }
  let(:title) do
    format(_("Your top-level group %{namespace_name} will move to a read-only state soon"),
      namespace_name: namespace.name)
  end

  subject(:component) { described_class.new(namespace: namespace, user: user, content_class: content_class) }

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Notification) do |notification_free_user_cap|
      allow(notification_free_user_cap).to receive(:over_limit?).and_return(notification_free_user_cap_over?)
    end
  end

  context 'when user is authorized to see alert' do
    before do
      namespace.add_developer(user)
    end

    context 'when over limit' do
      it 'has content for the notification alert' do
        render_inline(component)

        expect(page).to have_css(".gl-overflow-auto.#{content_class}")
        expect(page).to have_content(title)
        expect(page).to have_link('read-only', href: help_page_path('user/read_only_namespaces'))
        expect(page).to have_css('[data-testid="user-over-limit-free-plan-alert"]')
      end

      it 'renders all the expected tracking items' do
        render_inline(component)

        expect(page).to have_css('.js-user-over-limit-free-plan-alert[data-track-action="render"]' \
                                 '[data-track-label="user_limit_banner"]')
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
