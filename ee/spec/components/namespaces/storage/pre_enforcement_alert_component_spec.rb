# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::Storage::PreEnforcementAlertComponent, :saas, type: :component,
        feature_category: :consumables_cost_management do
  using RSpec::Parameterized::TableSyntax
  include NamespaceStorageHelpers

  let(:over_storage_limit) { false }

  let_it_be(:group) { create(:group_with_plan, :with_root_storage_statistics, plan: :free_plan) }
  let_it_be_with_refind(:user) { create(:user) }

  subject(:component) { described_class.new(context: group, user: user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
    group.root_storage_statistics.update!(
      storage_size: 5.gigabytes
    )
    set_notification_limit(group, megabytes: 500)

    allow_next_instance_of(::Namespaces::Storage::RootSize) do |group|
      allow(group).to receive(:above_size_limit?).and_return(over_storage_limit)
    end
  end

  context 'when user is allowed to see and dismiss' do
    before do
      group.add_maintainer(user)
    end

    it 'indicates the storage limit will be enforced soon in the banner text' do
      render_inline(component)

      expect(page).to have_text "A namespace storage limit will soon be enforced"
    end

    it 'includes the namespace name in the banner text' do
      render_inline(component)

      expect(page).to have_text group.name
    end

    it 'includes used_storage in the banner text' do
      render_inline(component)

      storage_size = 5.gigabytes / 1.gigabyte
      expect(page).to have_text "The namespace is currently using #{storage_size} GB of namespace storage"
    end

    it 'renders the correct callout data' do
      render_inline(component)

      expect(page).to have_css("[data-feature-id='namespace_storage_pre_enforcement_banner']")
      expect(page).to have_css("[data-dismiss-endpoint='#{group_callouts_path}']")
      expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
      expect(page).not_to have_css(".gl-alert-not-dismissible")
    end

    context 'when the user dismissed the banner under 14 days ago', :freeze_time do
      before do
        create(
          :group_callout,
          user: user,
          group: group,
          feature_name: 'namespace_storage_pre_enforcement_banner',
          dismissed_at: 1.day.ago
        )
      end

      it 'does not render the banner' do
        render_inline(component)

        expect(page).not_to have_text "A namespace storage limit will soon be enforced"
      end
    end

    context 'when the user dismissed the banner over 14 days ago', :freeze_time do
      before do
        create(
          :group_callout,
          user: user,
          group: group,
          feature_name: 'namespace_storage_pre_enforcement_banner',
          dismissed_at: 14.days.ago
        )
      end

      it 'does render the banner' do
        render_inline(component)

        expect(page).to have_text "A namespace storage limit will soon be enforced"
      end
    end

    describe 'alert links' do
      it 'includes the rollout_docs_link in the banner text' do
        render_inline(component)

        expect(page).to have_link(
          'A namespace storage limit',
          href: help_page_path(
            'user/usage_quotas',
            anchor: 'namespace-storage-limit'
          )
        )
      end

      it 'includes the learn_more_link in the banner text' do
        render_inline(component)

        expect(page).to have_link(
          'How can I manage my storage?',
          href: help_page_path(
            'user/usage_quotas',
            anchor: 'manage-your-storage-usage'
          )
        )
      end

      it 'includes the faq_link in the banner text' do
        render_inline(component)

        expect(page).to have_link(
          'FAQ',
          href: "#{Gitlab::Saas.about_pricing_url}faq-efficient-free-tier/" \
                "#storage-limits-on-gitlab-saas-free-tier"
        )
      end
    end

    context 'when namespace is below the notification limit' do
      before do
        create(
          :group_callout,
          user: user,
          group: group,
          feature_name: 'namespace_storage_pre_enforcement_banner'
        )
        allow(::EE::Gitlab::Namespaces::Storage::Enforcement).to receive(:show_pre_enforcement_alert?).and_return(false)
      end

      it 'does not render' do
        render_inline(component)

        expect(page).not_to have_css('.js-storage-enforcement-banner')
      end
    end

    context 'when user is allowed to see but not dismiss the alert' do
      let(:over_storage_limit) { true }

      before do
        group.add_maintainer(user)
      end

      it 'renders the correct callout data' do
        render_inline(component)

        expect(page).to have_css(".gl-alert-not-dismissible")
        expect(page).to have_css("[data-feature-id='namespace_storage_pre_enforcement_banner']")
        expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
      end
    end

    context 'when group does not meet the criteria to render the alert' do
      it 'does not render' do
        allow(::EE::Gitlab::Namespaces::Storage::Enforcement)
          .to receive(:show_pre_enforcement_alert?).and_return(false)

        render_inline(component)

        expect(page).not_to have_css('.js-storage-enforcement-banner')
      end
    end
  end

  context 'when user is not allowed to see the alert' do
    it 'does not render' do
      render_inline(component)

      expect(page).not_to have_css('.js-storage-enforcement-banner')
    end
  end
end
