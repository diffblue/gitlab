# frozen_string_literal: true

require "spec_helper"

RSpec.describe Namespaces::Storage::RepositoryLimitAlertComponent, :saas, type: :component, feature_category: :consumables_cost_management do
  let(:group) { build_stubbed(:group) }
  let(:user) { build_stubbed(:user) }
  let(:alert_title) { /You have used \d+% of the purchased storage for #{group.name}/ }
  let(:alert_title_over_storage_limit) { "You have used all available storage for #{group.name}" }
  let(:alert_title_free_tier) { "You have reached the free storage limit of 1,000 MiB on 72 projects" }

  let(:alert_message_below_limit) do
    "If a project reaches 100% of the storage quota (1,000 MiB) the project will be in a read-only state, " \
      "and you won't be able to push to your repository or add large files. To reduce storage usage, " \
      "reduce git repository and git LFS storage. For more information about storage limits, see our FAQ."
  end

  let(:alert_message_above_limit_no_purchased_storage) do
    "You have consumed all available storage and you can't push or add large files to projects over the " \
      "free tier limit (1,000 MiB). To remove the read-only state, reduce git repository and git LFS storage, " \
      "or purchase more storage. For more information about storage limits, see our FAQ."
  end

  let(:alert_message_above_limit_with_purchased_storage) do
    "You have consumed all available storage and you can't push or add large files to projects over the " \
      "free tier limit (1,000 MiB). To remove the read-only state, reduce git repository and git LFS storage, " \
      "or purchase more storage. For more information about storage limits, see our FAQ."
  end

  let(:alert_message_non_owner_copy) do
    "contact a user with the owner role for this namespace and ask them to purchase more storage"
  end

  subject(:component) { described_class.new(context: group, user: user) }

  describe 'repository enforcement' do
    before do
      stub_ee_application_setting(repository_size_limit: 1000.megabytes)
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(automatic_purchased_storage_allocation: true)
      stub_feature_flags(namespace_storage_limit: false)

      stub_member_access_level(group, owner: user)
    end

    context 'when namespace has no additional storage and is above size limit' do
      before do
        allow(group).to receive(:repository_size_excess_project_count).and_return(72)
        allow(group).to receive(:additional_purchased_storage_size).and_return(0)
        allow_next_instance_of(::Namespaces::Storage::RootExcessSize) do |size_checker|
          allow(size_checker).to receive(:usage_ratio).and_return(1)
          allow(size_checker).to receive(:above_size_limit?).and_return(true)
        end
      end

      it 'renders the alert title' do
        render_inline(component)
        expect(page).to have_content(alert_title_free_tier)
      end

      it 'renders the alert message' do
        render_inline(component)
        expect(page).to have_content(alert_message_above_limit_no_purchased_storage)
      end

      it 'renders the correct callout data' do
        render_inline(component)
        expect(page).to have_css("[data-feature-id='project_repository_limit_alert_error_threshold']")
        expect(page).to have_css("[data-dismiss-endpoint='#{group_callouts_path}']")
        expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
      end
    end

    context 'when namespace has additional storage' do
      context 'and under storage size limit' do
        before do
          allow(group).to receive(:additional_purchased_storage_size).and_return(1)
          allow_next_instance_of(::Namespaces::Storage::RootExcessSize) do |size_checker|
            allow(size_checker).to receive(:usage_ratio).and_return(0.75)
          end
        end

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
        before do
          allow(group).to receive(:additional_purchased_storage_size).and_return(1)
          allow_next_instance_of(::Namespaces::Storage::RootExcessSize) do |size_checker|
            allow(size_checker).to receive(:usage_ratio).and_return(1)
            allow(size_checker).to receive(:above_size_limit?).and_return(true)
          end
        end

        it 'renders the alert title' do
          render_inline(component)
          expect(page).to have_content(alert_title_over_storage_limit)
        end

        it 'renders the alert message' do
          render_inline(component)
          expect(page).to have_content(alert_message_above_limit_with_purchased_storage)
        end
      end
    end
  end

  context 'when user is not an owner' do
    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(automatic_purchased_storage_allocation: true)
      stub_feature_flags(namespace_storage_limit: false)
      stub_member_access_level(group, maintainer: user)
      allow(group).to receive(:additional_purchased_storage_size).and_return(0)
      allow_next_instance_of(::Namespaces::Storage::RootExcessSize) do |size_checker|
        allow(size_checker).to receive(:usage_ratio).and_return(1)
        allow(size_checker).to receive(:above_size_limit?).and_return(true)
      end
    end

    it 'renders the non-owner copy' do
      render_inline(component)
      expect(page).to have_content(alert_message_non_owner_copy)
    end
  end
end
