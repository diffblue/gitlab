# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SecurityFeaturesHelper do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:user, refind: true) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?).and_return(false)
  end

  describe '#group_level_security_dashboard_available?' do
    where(:group_level_compliance_dashboard_enabled, :read_group_compliance_dashboard_permission, :result) do
      false | false | false
      true  | false | false
      false | true  | false
      true  | true  | true
    end

    with_them do
      before do
        stub_licensed_features(group_level_compliance_dashboard: group_level_compliance_dashboard_enabled)
        allow(helper).to receive(:can?).with(user, :read_group_compliance_dashboard, group).and_return(read_group_compliance_dashboard_permission)
      end

      it 'returns the expected result' do
        expect(helper.group_level_compliance_dashboard_available?(group)).to eq(result)
      end
    end
  end

  describe '#group_level_credentials_inventory_available?' do
    where(:credentials_inventory_feature_enabled, :enforced_group_managed_accounts, :read_group_credentials_inventory_permission, :result) do
      true  | false | false | false
      true  | true  | false | false
      true  | false | true  | false
      true  | true  | true  | true
      false | false | false | false
      false | false | false | false
      false | false | true  | false
      false | true  | true  | false
    end

    with_them do
      before do
        stub_licensed_features(credentials_inventory: credentials_inventory_feature_enabled)
        allow(group).to receive(:enforced_group_managed_accounts?).and_return(enforced_group_managed_accounts)
        allow(helper).to receive(:can?).with(user, :read_group_credentials_inventory, group).and_return(read_group_credentials_inventory_permission)
      end

      it 'returns the expected result' do
        expect(helper.group_level_credentials_inventory_available?(group)).to eq(result)
      end
    end
  end

  describe '#group_level_security_dashboard_data' do
    subject { helper.group_level_security_dashboard_data(group) }

    before do
      allow(helper).to receive(:current_user).and_return(:user)
      allow(helper).to receive(:can?).and_return(true)
    end

    let(:expected_data) do
      {
        projects_endpoint: "http://localhost/api/v4/groups/#{group.id}/projects",
        group_full_path: group.full_path,
        no_vulnerabilities_svg_path: helper.image_path('illustrations/issues.svg'),
        empty_state_svg_path: helper.image_path('illustrations/security-dashboard-empty-state.svg'),
        survey_request_svg_path: helper.image_path('illustrations/security-dashboard_empty.svg'),
        dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
        vulnerabilities_export_endpoint: "/api/v4/security/groups/#{group.id}/vulnerability_exports",
        scanners: '[]',
        can_admin_vulnerability: 'true'
      }
    end

    it { is_expected.to eq(expected_data) }
  end
end
