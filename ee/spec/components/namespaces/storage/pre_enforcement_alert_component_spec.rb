# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::Storage::PreEnforcementAlertComponent, :saas, type: :component,
  feature_category: :consumables_cost_management do
  using RSpec::Parameterized::TableSyntax
  include NamespaceStorageHelpers
  include FreeUserCapHelpers

  let_it_be(:group) { create(:group_with_plan, :with_root_storage_statistics, plan: :free_plan) }
  let_it_be_with_refind(:user) { create(:user) }

  subject(:component) { described_class.new(context: group, user: user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true, automatic_purchased_storage_allocation: true)
    set_notification_limit(group, megabytes: 5_000)
    set_used_storage(group, megabytes: 5_100)
  end

  describe 'when qalifies for combnined users and storage alert' do
    let_it_be(:group) do
      create(:group_with_plan, :with_root_storage_statistics, :private, plan: :free_plan,
        name: 'over_users_and_storage')
    end

    before do
      group.add_guest(user)
      exceed_user_cap(group)
      enforce_free_user_caps
    end

    it 'does not render the alert' do
      render_inline(component)

      expect(page).not_to have_text "A namespace storage limit will soon be enforced"
    end
  end

  describe 'enforcement phases' do
    context 'when namespace is in pre-enforcement phase and no enforcement is set' do
      before do
        group.add_guest(user)
      end

      it 'renders the alert' do
        render_inline(component)

        expect(page).to have_css('.js-storage-pre-enforcement-alert')
      end
    end

    context 'when namespace is in the phased rollout of enforcement' do
      before do
        group.add_guest(user)
        enforce_namespace_storage_limit(group)
      end

      it 'renders the alert if used_storage is less than enforcement_limit' do
        set_enforcement_limit(group, megabytes: 6_000)

        render_inline(component)

        expect(page).to have_css('.js-storage-pre-enforcement-alert')
      end

      it 'does not render the alert if used_storage is higher than enforcement_limit' do
        set_enforcement_limit(group, megabytes: 4_000)

        render_inline(component)

        expect(page).not_to have_css('.js-storage-pre-enforcement-alert')
      end
    end

    context 'when namespace is NOT in phased rollout and uses dashboard limit for enforcement' do
      # After we enable Namespace enforcement, namespaces created after that date will use
      # the dashboard limit https://about.gitlab.com/pricing/faq-efficient-free-tier/#q-what-is-changing-with-storage
      # the dashboard limit is stored in the storage_size_limit plan limit

      before do
        group.add_guest(user)
        enforce_namespace_storage_limit(group)
      end

      it 'renders the alert if used_storage is less than storage_size_limit' do
        set_dashboard_limit(group, megabytes: 6_000)

        render_inline(component)

        expect(page).to have_css('.js-storage-pre-enforcement-alert')
      end

      it 'does not render the alert if used_storage is higher than storage_size_limit' do
        set_dashboard_limit(group, megabytes: 4_000)

        render_inline(component)

        expect(page).not_to have_css('.js-storage-pre-enforcement-alert')
      end
    end
  end

  context 'when user is allowed to see and dismiss' do
    before do
      group.add_guest(user)
    end

    it 'indicates the storage limit will be enforced soon in the alert text' do
      render_inline(component)

      expect(page).to have_text "A namespace storage limit will soon be enforced"
    end

    it 'includes the namespace name in the alert text' do
      render_inline(component)

      expect(page).to have_text group.name
    end

    it 'includes used_storage in the alert text' do
      render_inline(component)

      storage_size = 5.gigabytes / 1.gigabyte
      expect(page).to have_text "The namespace is currently using #{storage_size} GiB of namespace storage"
    end

    it 'renders the correct callout data' do
      render_inline(component)

      expect(page).to have_css("[data-feature-id='namespace_storage_pre_enforcement_banner']")
      expect(page).to have_css("[data-dismiss-endpoint='#{group_callouts_path}']")
      expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
    end

    context 'when the user dismissed the alert under 14 days ago', :freeze_time do
      before do
        create(
          :group_callout,
          user: user,
          group: group,
          feature_name: 'namespace_storage_pre_enforcement_banner',
          dismissed_at: 1.day.ago
        )
      end

      it 'does not render the alert' do
        render_inline(component)

        expect(page).not_to have_text "A namespace storage limit will soon be enforced"
      end
    end

    context 'when the user dismissed the alert over 14 days ago', :freeze_time do
      before do
        create(
          :group_callout,
          user: user,
          group: group,
          feature_name: 'namespace_storage_pre_enforcement_banner',
          dismissed_at: 14.days.ago
        )
      end

      it 'does render the alert' do
        render_inline(component)

        expect(page).to have_text "A namespace storage limit will soon be enforced"
      end
    end

    describe 'alert links' do
      it 'includes the rollout_docs_link in the alert text' do
        render_inline(component)

        expect(page).to have_link(
          'A namespace storage limit',
          href: help_page_path(
            'user/usage_quotas',
            anchor: 'namespace-storage-limit'
          )
        )
      end

      it 'includes the learn_more_link in the alert text' do
        render_inline(component)

        expect(page).to have_link(
          'How can I manage my storage',
          href: help_page_path(
            'user/usage_quotas',
            anchor: 'manage-your-storage-usage'
          )
        )
      end

      it 'includes the faq_link in the alert text' do
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
        enforce_namespace_storage_limit(group)
        set_notification_limit(group, megabytes: 6_000)
      end

      it 'does not render' do
        render_inline(component)

        expect(page).not_to have_css('.js-storage-pre-enforcement-alert')
      end
    end

    context 'when group does not meet the criteria to render the alert' do
      it 'does not render' do
        set_notification_limit(group, megabytes: 6_000)

        render_inline(component)

        expect(page).not_to have_css('.js-storage-pre-enforcement-alert')
      end
    end
  end

  context 'when user is not allowed to see the alert' do
    it 'does not render' do
      render_inline(component)

      expect(page).not_to have_css('.js-storage-pre-enforcement-alert')
    end
  end
end
