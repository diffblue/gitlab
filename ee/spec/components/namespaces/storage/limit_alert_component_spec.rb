# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::LimitAlertComponent, :saas, type: :component, feature_category: :consumables_cost_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be_with_refind(:user) { create(:user) }

  let(:alert_title) { "You have used 75% of the storage quota for #{group.name} (0 Bytes of 0 Bytes)" }

  let(:alert_title_repository_above_limit_no_purchased_storage) do
    "You have reached the free storage limit of 0 Bytes on one or more projects"
  end

  let(:alert_title_repository_above_limit_with_purchased_storage) do
    "#{group.name} contains 1 locked project"
  end

  let(:alert_message_repository_below_limit) do
    "If you reach 100% storage capacity, you will not be able to: push to your repository, " \
      "create pipelines, create issues or add comments. To reduce storage capacity, delete unused " \
      "repositories, artifacts, wikis, issues, and pipelines. Learn more."
  end

  let(:alert_message_repository_above_limit_no_purchased_storage) do
    "Please purchase additional storage to unlock your projects over the free 0 Bytes project limit. " \
      "You can't push to your repository, create pipelines, create issues or add comments. " \
      "To reduce storage capacity, delete unused repositories, artifacts, wikis, issues, and pipelines. Learn more."
  end

  let(:alert_message_repository_above_limit_with_purchased_storage) do
    "You have consumed all of your additional storage, please purchase more to unlock your projects over the free " \
      "0 Bytes limit. You can't push to your repository, create pipelines, create issues or add comments. " \
      "To reduce storage capacity, delete unused repositories, artifacts, wikis, issues, and pipelines. Learn more."
  end

  let(:alert_message_namespace_below_limit) do
    "If #{group.name} exceeds the storage quota, all projects in the namespace will be locked " \
      "and actions will be restricted. Which actions become restricted? Manage your storage usage or, " \
      "if you are a namespace Owner, purchase additional storage. Learn more."
  end

  let(:alert_message_namespace_above_limit) do
    "#{group.name} is now read-only. Projects under this namespace are locked and actions are restricted. " \
      "Which actions are restricted? Manage your storage usage or, " \
      "if you are a namespace Owner, purchase additional storage. Learn more."
  end

  subject(:component) { described_class.new(context: group, user: user) }

  context 'for repository type enforcement' do
    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(automatic_purchased_storage_allocation: true)
      stub_feature_flags(namespace_storage_limit: false)

      allow_next_instance_of(::Namespaces::Storage::RootExcessSize) do |size_checker|
        allow(size_checker).to receive(:usage_ratio).and_return(0.75)
      end

      group.add_owner(user)
    end

    it 'renders the alert title' do
      render_inline(component)
      expect(page).to have_content(alert_title)
    end

    it 'renders the alert message' do
      render_inline(component)
      expect(page).to have_content(alert_message_repository_below_limit)
    end

    context 'when storage used is over limit and user has not purchased additional storage' do
      before do
        allow(group).to receive(:contains_locked_projects?).and_return(true)
        allow(group).to receive(:additional_purchased_storage_size).and_return(0)
        allow_next_instance_of(::Namespaces::Storage::RootExcessSize) do |size_checker|
          allow(size_checker).to receive(:usage_ratio).and_return(1)
          allow(size_checker).to receive(:above_size_limit?).and_return(true)
        end
      end

      it 'renders the alert title' do
        render_inline(component)
        expect(page).to have_content(alert_title_repository_above_limit_no_purchased_storage)
      end

      it 'renders the alert message' do
        render_inline(component)
        expect(page).to have_content(alert_message_repository_above_limit_no_purchased_storage)
      end
    end

    context 'when storage used is over limit and user has purchased additional storage' do
      before do
        allow(group).to receive(:contains_locked_projects?).and_return(true)
        allow(group).to receive(:repository_size_excess_project_count).and_return(1)
        allow(group).to receive(:additional_purchased_storage_size).and_return(10)
        allow_next_instance_of(::Namespaces::Storage::RootExcessSize) do |size_checker|
          allow(size_checker).to receive(:usage_ratio).and_return(1)
          allow(size_checker).to receive(:above_size_limit?).and_return(true)
        end
      end

      it 'renders the alert title' do
        render_inline(component)
        expect(page).to have_content(alert_title_repository_above_limit_with_purchased_storage)
      end

      it 'renders the alert message' do
        render_inline(component)
        expect(page).to have_content(alert_message_repository_above_limit_with_purchased_storage)
      end
    end
  end

  context 'for namespace type enforcement' do
    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(enforce_namespace_storage_limit: true)
      stub_ee_application_setting(automatic_purchased_storage_allocation: true)

      allow_next_instance_of(::Namespaces::Storage::RootSize) do |size_checker|
        allow(size_checker).to receive(:usage_ratio).and_return(0.75)
      end

      group.add_maintainer(user)
    end

    it 'renders the alert title' do
      render_inline(component)
      expect(page).to have_content(alert_title)
    end

    it 'renders the alert message' do
      render_inline(component)
      expect(page).to have_content(alert_message_namespace_below_limit)
    end

    context 'when storage used is over limit' do
      before do
        allow_next_instance_of(::Namespaces::Storage::RootSize) do |size_checker|
          allow(size_checker).to receive(:usage_ratio).and_return(1.1)
        end

        group.add_maintainer(user)
      end

      it 'renders above limit alert message' do
        render_inline(component)
        expect(page).to have_content(alert_message_namespace_above_limit)
      end
    end

    describe 'purchase more storage link' do
      it 'does not render link if user is not an owner of root group' do
        render_inline(component)
        expect(page).not_to have_link(
          'Purchase more storage',
          href: buy_storage_subscriptions_path(selected_group: group.root_ancestor.id)
        )
      end

      it 'renders link if user is an owner of root group' do
        allow(Ability).to receive(:allowed?).with(user, :maintainer_access, group.root_ancestor).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :owner_access, group.root_ancestor).and_return(true)

        render_inline(component)
        expect(page).to have_link(
          'Purchase more storage',
          href: buy_storage_subscriptions_path(selected_group: group.root_ancestor.id)
        )
      end
    end

    it 'renders Usage Quotas link' do
      render_inline(component)
      expect(page).to have_link(
        'View usage details',
        href: usage_quotas_path(group.root_ancestor, anchor: 'storage-quota-tab')
      )
    end

    describe 'alert callout data' do
      where(:usage_ratio, :alert_level, :user_namespace) do
        0.85 | :warning   | false
        0.95 | :alert     | true
        1.00 | :error     | false
      end

      with_them do
        before do
          allow(group.root_ancestor).to receive(:user_namespace?).and_return(user_namespace)

          if user_namespace
            allow(Ability).to receive(:allowed?).with(user, :owner_access, group.root_ancestor).and_return(true)
          end

          allow_next_instance_of(::Namespaces::Storage::RootSize) do |size_checker|
            allow(size_checker).to receive(:usage_ratio).and_return(usage_ratio)
          end
        end

        it 'renders the correct callout data' do
          render_inline(component)

          dismiss_endpoint_path = user_namespace ? callouts_path : group_callouts_path

          expect(page).to have_css("[data-feature-id='namespace_storage_limit_banner_#{alert_level}_threshold']")
          expect(page).to have_css("[data-dismiss-endpoint='#{dismiss_endpoint_path}']")
          expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
        end
      end
    end

    describe 'icon and alert variant' do
      where(:usage_ratio, :alert_level, :variant, :icon) do
        0.85 | :warning   | 'warning' | 'warning'
        0.95 | :alert     | 'danger'  | 'error'
        1.00 | :error     | 'danger'  | 'error'
      end

      with_them do
        before do
          allow_next_instance_of(::Namespaces::Storage::RootSize) do |size_checker|
            allow(size_checker).to receive(:usage_ratio).and_return(usage_ratio)
          end
        end

        it 'renders the correct icon and variant' do
          render_inline(component)

          expect(page).to have_css("[data-testid='#{icon}-icon']")
          expect(page).to have_css(".gl-alert-#{variant}")
        end
      end
    end

    context 'when user has dismissed banner' do
      before do
        create(
          :group_callout,
          user: user,
          group: group,
          feature_name: 'namespace_storage_limit_banner_warning_threshold'
        )

        allow_next_instance_of(::Namespaces::Storage::RootSize) do |size_checker|
          allow(size_checker).to receive(:usage_ratio).and_return(0.75)
        end
      end

      it 'does not render' do
        render_inline(component)
        expect(page).not_to have_css('.js-namespace-storage-alert')
      end
    end
  end
end
