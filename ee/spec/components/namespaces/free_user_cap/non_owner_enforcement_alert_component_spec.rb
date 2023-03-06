# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::NonOwnerEnforcementAlertComponent, :saas, :aggregate_failures, type: :component,
  feature_category: :experimentation_conversion do
  let_it_be(:namespace, reload: true) { create(:group) }
  let_it_be(:user, refind: true) { create(:user) }
  let(:content_class) { '_content_class_' }
  let(:free_user_cap_over_limit?) { true }
  let(:title) do
    "Your top-level group #{namespace.name} is over the #{::Namespaces::FreeUserCap.dashboard_limit} " \
      "user limit and has been placed in a read-only state."
  end

  subject(:component) do
    described_class.new(namespace: namespace, user: user, content_class: content_class)
  end

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Enforcement) do |free_user_cap|
      allow(free_user_cap).to receive(:over_limit?).and_return(free_user_cap_over_limit?)
    end
  end

  context 'when user is authorized to see alert' do
    before do
      namespace.add_guest(user)
    end

    context 'when over the limit' do
      it 'has content for the alert' do
        render_inline(component)

        expect(page).to have_content(title)
        expect(page).to have_link('read-only', href: help_page_path('user/free_user_limit'))

        expect(page).to have_css(".gl-overflow-auto.#{content_class}")

        expect(page).to have_css('[data-testid="user-over-limit-free-plan-alert"]')
      end
    end

    context 'when limit has not been reached' do
      let(:free_user_cap_over_limit?) { false }

      it 'does not render the alert' do
        render_inline(component)

        expect(page).not_to have_content(title)
      end
    end
  end

  context 'when user is not authorized to see alert' do
    before do
      namespace.add_owner(user)
    end

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
