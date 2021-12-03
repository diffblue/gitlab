# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::AdministrationMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be_with_refind(:parent_group) do
    create(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let_it_be_with_refind(:child_group) do
    create(:group, :private, parent: parent_group).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:group) { parent_group }
  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    subject { menu.render? }

    context 'when feature flag :group_administration_nav_item is enabled' do
      specify { is_expected.to be true }

      context 'when group is a subgroup' do
        let(:group) { child_group }

        specify { is_expected.to be false }
      end

      context 'when user cannot admin group' do
        let(:user) { nil }

        specify { is_expected.to be false }
      end
    end

    context 'when feature flag :group_administration_nav_item is disabled' do
      specify do
        stub_feature_flags(group_administration_nav_item: false)

        is_expected.to be false
      end
    end
  end

  describe 'Menu items' do
    subject(:menu_item) { menu.renderable_items.find { |e| e.item_id == item_id } }

    describe 'SAML SSO menu' do
      let(:item_id) { :saml_sso }
      let(:saml_enabled) { true }

      before do
        stub_licensed_features(group_saml: saml_enabled)
        allow(::Gitlab::Auth::GroupSaml::Config).to receive(:enabled?).and_return(saml_enabled)
      end

      context 'when SAML is disabled' do
        let(:saml_enabled) { false }

        specify { is_expected.to be_nil }
      end

      context 'when SAML is enabled' do
        specify { is_expected.to be_present }

        context 'when user does not have access' do
          let(:user) { nil }

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'Usage quotas menu' do
      let(:item_id) { :usage_quotas }
      let(:usage_quotas_enabled) { true }

      before do
        stub_licensed_features(usage_quotas: usage_quotas_enabled)
      end

      specify { is_expected.to be_present }

      context 'when user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Billing menu' do
      let(:item_id) { :billing }
      let(:check_billing) { true }

      before do
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(check_billing)
      end

      specify { is_expected.to be_present }

      context 'when user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end

      context 'with billing_in_side_nav experiment', :experiment do
        include Rails.application.routes.url_helpers

        let(:settings_path) { group_billings_path(context.group) }

        context 'with control experience' do
          before do
            stub_experiments(billing_in_side_nav: :control)
          end

          it 'does not modify the `active_routes` attribute' do
            expect(menu_item.active_routes).to eq(path: 'billings#index')
          end
        end

        context 'with candidate experience' do
          before do
            stub_experiments(billing_in_side_nav: :candidate)
          end

          it 'modifies the `active_routes` attribute' do
            exclude_page = group_billings_path(context.group, from: :side_nav)

            expect(menu_item.active_routes).to eq(page: settings_path, exclude_page: exclude_page)
          end
        end
      end
    end
  end
end
