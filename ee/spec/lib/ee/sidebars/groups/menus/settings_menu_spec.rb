# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::SettingsMenu do
  let_it_be(:owner) { create(:user) }

  let_it_be_with_refind(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:show_promotions) { false }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group, show_promotions: show_promotions) }
  let(:menu) { described_class.new(context) }

  describe 'Menu Items' do
    subject { menu.renderable_items.find { |e| e.item_id == item_id } }

    describe 'LDAP sync menu' do
      let(:item_id) { :ldap_sync }

      before do
        allow(Gitlab::Auth::Ldap::Config).to receive(:group_sync_enabled?).and_return(sync_enabled)
      end

      context 'when group LDAP sync is not enabled' do
        let(:sync_enabled) { false }

        specify { is_expected.to be_nil }
      end

      context 'when group LDAP sync is enabled' do
        let(:sync_enabled) { true }

        context 'when user can admin LDAP syncs' do
          specify { is_expected.to be_present }
        end

        context 'when user cannot admin LDAP syncs' do
          let(:user) { nil }

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'SAML SSO menu' do
      let(:item_id) { :saml_sso }
      let(:group_admin_nav_enabled) { false }
      let(:saml_enabled) { true }

      before do
        stub_feature_flags(group_administration_nav_item: group_admin_nav_enabled)
        stub_licensed_features(group_saml: saml_enabled)
        allow(::Gitlab::Auth::GroupSaml::Config).to receive(:enabled?).and_return(saml_enabled)
      end

      context 'when SAML is disabled' do
        let(:saml_enabled) { false }

        specify { is_expected.to be_nil }
      end

      context 'when SAML is enabled' do
        context 'when :group_administration_nav_item feature is disabled' do
          specify { is_expected.to be_present }

          context 'when user cannot admin group SAML' do
            let(:user) { nil }

            specify { is_expected.to be_nil }
          end
        end

        context 'when :group_administration_nav_item feature is enabled' do
          let(:group_admin_nav_enabled) { true }

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'SAML group links menu' do
      let(:item_id) { :saml_group_links }
      let(:saml_group_links_enabled) { true }

      before do
        allow(::Gitlab::Auth::GroupSaml::Config).to receive(:enabled?).and_return(saml_group_links_enabled)
        allow(group).to receive(:saml_group_sync_available?).and_return(saml_group_links_enabled)
      end

      context 'when SAML group links feature is disabled' do
        let(:saml_group_links_enabled) { false }

        specify { is_expected.to be_nil }
      end

      context 'when SAML group links feature is enabled' do
        specify { is_expected.to be_present }

        context 'when user cannot admin SAML group links' do
          let(:user) { nil }

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'Webhooks menu' do
      let(:item_id) { :webhooks }
      let(:group_webhooks_enabled) { true }

      before do
        stub_licensed_features(group_webhooks: group_webhooks_enabled)
      end

      context 'when licensed feature :group_webhooks is not enabled' do
        let(:group_webhooks_enabled) { false }

        specify { is_expected.to be_nil }
      end

      context 'when show_promotions is enabled' do
        let(:show_promotions) { true }

        specify { is_expected.to be_present }
      end

      context 'when licensed feature :group_webhooks is enabled' do
        specify { is_expected.to be_present }
      end
    end

    describe 'Usage quotas menu' do
      let(:item_id) { :usage_quotas }
      let(:group_admin_nav_enabled) { false }
      let(:usage_quotas_enabled) { true }

      before do
        stub_feature_flags(group_administration_nav_item: group_admin_nav_enabled)
        stub_licensed_features(usage_quotas: usage_quotas_enabled)
      end

      specify { is_expected.to be_present }

      context 'when feature flag :group_administration_nav_item is enabled' do
        let(:group_admin_nav_enabled) { true }

        specify { is_expected.to be_nil }
      end

      context 'when usage_quotas licensed feature is not enabled' do
        let(:usage_quotas_enabled) { false }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Billing menu' do
      let(:item_id) { :billing }
      let(:group_admin_nav_enabled) { false }
      let(:check_billing) { true }

      before do
        stub_feature_flags(group_administration_nav_item: group_admin_nav_enabled)
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(check_billing)
      end

      specify { is_expected.to be_present }

      context 'when feature flag :group_administration_nav_item is enabled' do
        let(:group_admin_nav_enabled) { true }

        specify { is_expected.to be_nil }
      end

      context 'when group billing does not apply' do
        let(:check_billing) { false }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Reporting menu' do
      let(:item_id) { :reporting }
      let(:feature_enabled) { true }

      before do
        allow(group).to receive(:unique_project_download_limit_enabled?) { feature_enabled }
      end

      it { is_expected.to be_present }

      context 'when feature is not enabled' do
        let(:feature_enabled) { false }

        it { is_expected.to be_nil }
      end
    end
  end
end
