# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::Storage::LimitAlertComponent, :saas, type: :component, feature_category: :consumables_cost_management do
  include NamespaceStorageHelpers
  using RSpec::Parameterized::TableSyntax

  let(:user) { build_stubbed(:user) }
  let(:gitlab_subscription) { build_stubbed(:gitlab_subscription) }
  let(:additional_purchased_storage_size) { 0 }
  let(:group) do
    build_stubbed(
      :group,
      additional_purchased_storage_size: additional_purchased_storage_size,
      gitlab_subscription: gitlab_subscription
    )
  end

  let(:usage_ratio) { 0.8 }
  let(:above_size_limit) { false }
  let(:alert_title) { /You have used \d+% of the storage quota for #{group.name}/ }
  let(:alert_title_free_tier) { "You have reached the free storage limit of 1,000 MiB for #{group.name}" }

  let(:alert_message_below_limit) do
    "If #{group.name} exceeds the storage quota, your ability to write new data to this namespace will be " \
      "restricted. Which actions become restricted? To prevent your projects from being in a read-only state manage " \
      "your storage usage, or purchase more storage. For more information about storage limits, see our FAQ."
  end

  let(:alert_message_above_limit_no_purchased_storage) do
    "#{group.name} is now read-only. Your ability to write new data to this namespace is restricted. " \
      "Which actions are restricted? To remove the read-only state manage your storage usage, or purchase " \
      "more storage. For more information about storage limits, see our FAQ."
  end

  let(:alert_message_above_limit_with_purchased_storage) do
    "#{group.name} is now read-only. Your ability to write new data to this namespace is restricted. " \
      "Which actions are restricted? To remove the read-only state manage your storage usage, or purchase " \
      "more storage. For more information about storage limits, see our FAQ."
  end

  let(:alert_message_non_owner_copy) do
    "contact a user with the owner role for this namespace and ask them to purchase more storage"
  end

  subject(:component) { described_class.new(context: group, user: user) }

  describe 'namespace enforcement' do
    before do
      enforce_namespace_storage_limit(group)

      allow_next_instance_of(::Namespaces::Storage::RootSize) do |size_checker|
        allow(size_checker).to receive(:usage_ratio).and_return(usage_ratio)
        allow(size_checker).to receive(:above_size_limit?).and_return(above_size_limit)
      end

      allow(group).to receive(:actual_size_limit).and_return(1000.megabytes)
      stub_member_access_level(group, owner: user)
    end

    context 'when namespace has no additional storage' do
      let(:additional_purchased_storage_size) { 0 }

      context 'and under storage size limit' do
        let(:usage_ratio) { 0.8 }
        let(:above_size_limit) { false }

        it 'renders the alert title' do
          render_inline(component)
          expect(page).to have_content(alert_title)
        end

        it 'renders the alert message' do
          render_inline(component)
          expect(page).to have_content(alert_message_below_limit)
        end

        it 'allows to dismiss alert' do
          render_inline(component)
          expect(page).to have_css("[data-testid='close-icon']")
        end
      end

      context 'and above storage size limit' do
        let(:usage_ratio) { 1 }
        let(:above_size_limit) { true }

        it 'renders the alert title' do
          render_inline(component)
          expect(page).to have_content(alert_title_free_tier)
        end

        it 'renders the alert message' do
          render_inline(component)
          expect(page).to have_content(alert_message_above_limit_no_purchased_storage)
        end

        it 'does not allow to dismiss alert' do
          render_inline(component)
          expect(page).not_to have_css("[data-testid='close-icon']")
        end
      end
    end

    context 'when namespace has additional storage' do
      let(:additional_purchased_storage_size) { 1 }

      context 'and under storage size limit' do
        let(:usage_ratio) { 0.8 }
        let(:above_size_limit) { false }

        it 'renders the alert title' do
          render_inline(component)
          expect(page).to have_content(alert_title)
        end

        it 'renders the alert message' do
          render_inline(component)
          expect(page).to have_content(alert_message_below_limit)
        end
      end

      context 'and above storage size limit' do
        let(:usage_ratio) { 1 }
        let(:above_size_limit) { true }

        it 'renders the alert title' do
          render_inline(component)
          expect(page).to have_content(alert_title)
        end

        it 'renders the alert message' do
          render_inline(component)
          expect(page).to have_content(alert_message_above_limit_with_purchased_storage)
        end
      end
    end
  end

  describe '#render?' do
    where(
      :enforce_namespace_storage_limit,
      :automatic_purchased_storage_allocation,
      :should_check_namespace_plan,
      :user_present,
      :user_has_access,
      :alert_level,
      :user_has_dismissed_alert,
      :should_render
    ) do
      true  | true  | true  | true  | true  | :error | false | true
      false | true  | true  | true  | true  | :error | false | false
      true  | false | true  | true  | true  | :error | false | false
      true  | true  | false | true  | true  | :error | false | false
      true  | true  | true  | false | true  | :error | false | false
      true  | true  | true  | true  | false | :error | false | false
      true  | true  | true  | true  | true  | :none  | false | false
      true  | true  | true  | true  | true  | :error | true  | false
    end

    with_them do
      before do
        stub_ee_application_setting(enforce_namespace_storage_limit: enforce_namespace_storage_limit)
        stub_ee_application_setting(automatic_purchased_storage_allocation: automatic_purchased_storage_allocation)
        stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)

        allow(user).to receive(:present?).and_return(user_present)
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:user_has_access?).and_return(user_has_access)
          allow(instance).to receive(:alert_level).and_return(alert_level)
          allow(instance).to receive(:user_has_dismissed_alert?).and_return(user_has_dismissed_alert)
        end
      end

      it 'renders the alert title' do
        render_inline(component)
        expectation = should_render ? have_content(alert_title) : have_no_content(:all)
        expect(page).to expectation
      end
    end
  end

  context 'when user is not an owner' do
    where(:usage_ratio, :alert_message_copy) do
      0.85 | "exceeds the storage quota"
      1.00 | "is now read-only"
    end

    with_them do
      before do
        enforce_namespace_storage_limit(group)

        stub_member_access_level(group, maintainer: user)

        allow_next_instance_of(::Namespaces::Storage::RootSize) do |size_checker|
          allow(size_checker).to receive(:usage_ratio).and_return(usage_ratio)
          allow(size_checker).to receive(:above_size_limit?).and_return(usage_ratio >= 1)
        end
      end

      it 'renders the message' do
        render_inline(component)
        expect(page).to have_content(alert_message_copy)
      end

      it 'renders the non-owner copy' do
        render_inline(component)
        expect(page).to have_content(alert_message_non_owner_copy)
      end
    end
  end
end
