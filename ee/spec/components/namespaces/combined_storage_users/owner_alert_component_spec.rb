# frozen_string_literal: true

require "spec_helper"
RSpec.describe Namespaces::CombinedStorageUsers::OwnerAlertComponent, :saas, type: :component,
  feature_category: :consumables_cost_management do
  include NamespaceStorageHelpers
  include FreeUserCapHelpers

  let(:namespace) { build_stubbed(:group, :private, gitlab_subscription: build_stubbed(:gitlab_subscription)) }
  let(:user) { build_stubbed(:user) }

  let(:content_class) { '_content_class_' }
  let(:over_storage_limit) { true }
  let(:over_users_limit) { true }
  let(:alert_title) { 'Free top-level groups will soon be limited to 5 users and 5 GiB of data' }

  subject(:component) { described_class.new(root_namespace: namespace, user: user, content_class: content_class) }

  before do
    enforce_free_user_caps
    set_dashboard_limit(namespace, megabytes: 5_000)
    allow(::Namespaces::Storage::Enforcement).to receive(:show_pre_enforcement_alert?)
      .with(namespace).and_return(over_storage_limit)
    allow_next_instance_of(::Namespaces::FreeUserCap::EnforcementWithoutStorage, namespace) do |instance|
      allow(instance).to receive(:over_limit?).and_return(over_users_limit)
    end
  end

  context 'when user is authorized to see alert' do
    before do
      stub_member_access_level(namespace, owner: user)
    end

    context 'when over both limits' do
      it 'renders the alert' do
        render_inline(component)

        expect(page).to have_content(alert_title)
      end

      it 'renders all the expected tracking items' do
        render_inline(component)

        expect(page).to have_css('[data-track-action="render"]' \
                                 '[data-track-label="storage_users_limit_banner"]')
        expect(page).to have_css('[data-track-action="click_button"]' \
                                 '[data-track-label="manage_users_storage_limits"]')
        expect(page).to have_css('[data-track-action="click_button"]' \
                                 '[data-track-label="explore_paid_plans"]')
      end

      context 'when the user dismissed the alert under 14 days ago', :freeze_time do
        let(:user) do
          build_stubbed(
            :user,
            group_callouts: [build_stubbed(
              :group_callout,
              group: namespace,
              feature_name: 'namespace_over_storage_users_combined_alert',
              dismissed_at: 1.day.ago
            )]
          )
        end

        it 'does not render the alert' do
          render_inline(component)

          expect(page).not_to have_content(alert_title)
        end
      end

      context 'when the user dismissed the alert 14 or more days ago', :freeze_time do
        let(:user) do
          build_stubbed(
            :user,
            group_callouts: [build_stubbed(
              :group_callout,
              group: namespace,
              feature_name: 'namespace_over_storage_users_combined_alert',
              dismissed_at: 14.days.ago
            )]
          )
        end

        it 'does render the alert' do
          render_inline(component)

          expect(page).to have_content(alert_title)
        end
      end
    end

    context 'when not over one of the limits' do
      let(:over_users_limit) { false }

      it 'does not render the alert' do
        render_inline(component)

        expect(page).not_to have_content(alert_title)
      end
    end
  end

  context 'when the user is not authorized to see the alert' do
    context 'when not an owner' do
      before do
        stub_member_access_level(namespace, maintainer: user)
      end

      it 'does not render the alert' do
        render_inline(component)

        expect(page).not_to have_content(alert_title)
      end
    end

    context 'when no access level' do
      it 'does not render the alert' do
        render_inline(component)

        expect(page).not_to have_content(alert_title)
      end
    end
  end

  context 'when user does not exist' do
    let(:user) { nil }

    it 'does not render the alert' do
      render_inline(component)

      expect(page).not_to have_content(alert_title)
    end
  end
end
