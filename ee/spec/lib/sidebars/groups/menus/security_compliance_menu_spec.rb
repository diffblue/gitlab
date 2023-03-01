# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::SecurityComplianceMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be_with_refind(:group) do
    create(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:show_group_discover_security) { false }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group, show_discover_group_security: show_group_discover_security) }
  let(:menu) { described_class.new(context) }

  describe '#link' do
    subject { menu.link }

    context 'when menu has menu items' do
      it 'returns first visible menu item link' do
        expect(subject).to eq menu.renderable_items.first.link
      end
    end

    context 'when menu does no have any menu item' do
      let(:user) { nil }

      it 'returns show group security page' do
        expect(subject).to eq "/groups/#{group.full_path}/-/security/discover"
      end
    end
  end

  describe '#title' do
    subject { menu.title }

    specify do
      is_expected.to eq 'Security and Compliance'
    end

    context 'when menu does not have any menu items' do
      let(:user) { nil }

      specify do
        is_expected.to eq 'Security'
      end
    end
  end

  describe '#render?' do
    subject { menu.render? }

    it 'returns true if there are menu items' do
      is_expected.to be true
    end

    context 'when there are no menu items' do
      let(:user) { nil }

      it 'returns false if there are no menu items' do
        is_expected.to be false
      end

      context 'when show group discover security option is enabled' do
        let(:show_group_discover_security) { true }

        specify { is_expected.to be true }
      end
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'menu access rights' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Security Dashboard' do
      let(:item_id) { :security_dashboard }

      context 'when security_dashboard feature is enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        specify { is_expected.not_to be_nil }
      end

      context 'when security_dashboard feature is not enabled' do
        specify { is_expected.to be_nil }
      end
    end

    describe 'Vulnerability Report' do
      let(:item_id) { :vulnerability_report }

      context 'when security_dashboard feature is enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        specify { is_expected.not_to be_nil }
      end

      context 'when security_dashboard feature is not enabled' do
        specify { is_expected.to be_nil }
      end
    end

    describe 'Compliance' do
      let(:item_id) { :compliance }

      context 'when group_level_compliance_dashboard feature is enabled' do
        before do
          stub_licensed_features(group_level_compliance_dashboard: true)
        end

        it_behaves_like 'menu access rights'
      end

      context 'when group_level_compliance_dashboard feature is not enabled' do
        specify { is_expected.to be_nil }
      end
    end

    describe 'Credentials' do
      let(:item_id) { :credentials }

      context 'when credentials_inventory feature is enabled' do
        before do
          stub_licensed_features(credentials_inventory: true)
        end

        context 'when group magement is not enforced' do
          specify { is_expected.to be_nil }
        end

        context 'when group magement is enforced' do
          before do
            allow(group).to receive(:enforced_group_managed_accounts?).and_return(true)
          end

          it_behaves_like 'menu access rights'
        end
      end

      context 'when credentials_inventory feature is not enabled' do
        specify { is_expected.to be_nil }
      end
    end

    describe 'Security Policies' do
      let(:item_id) { :scan_policies }

      context 'when scan_policies feature is enabled' do
        before do
          stub_licensed_features(security_orchestration_policies: true)
        end

        context 'when group security policies feature is disabled' do
          it_behaves_like 'menu access rights'
        end

        context 'when scan_policies feature is not enabled' do
          before do
            stub_licensed_features(security_orchestration_policies: false)
          end

          specify { is_expected.to be_nil }
        end
      end
    end

    describe 'Audit Events' do
      let(:item_id) { :audit_events }

      context 'when audit_events feature is enabled' do
        before do
          stub_licensed_features(audit_events: true)
        end

        it_behaves_like 'menu access rights'
      end

      context 'when audit_events feature is not enabled' do
        before do
          stub_licensed_features(audit_events: false)
        end

        specify { is_expected.to be_nil }
      end
    end
  end
end
