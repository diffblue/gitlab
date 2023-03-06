# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::SecurityComplianceMenu, feature_category: :navigation do
  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:show_promotions) { true }
  let(:show_discover_project_security) { true }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_promotions: show_promotions, show_discover_project_security: show_discover_project_security) }

  describe '#link' do
    subject { described_class.new(context) }

    let(:show_promotions) { false }
    let(:show_discover_project_security) { false }

    using RSpec::Parameterized::TableSyntax

    where(:show_discover_project_security, :security_dashboard_feature, :dependency_scanning_feature, :audit_events_feature, :expected_link) do
      true  | true  | true  | true  | '/-/security/discover'
      false | true  | true  | true  | '/-/security/dashboard'
      false | false | true  | true  | '/-/dependencies'
      false | false | false | true  | '/-/audit_events'
      false | false | false | false | '/-/security/configuration'
    end

    with_them do
      it 'returns the expected link' do
        stub_licensed_features(security_dashboard: security_dashboard_feature, audit_events: audit_events_feature, dependency_scanning: dependency_scanning_feature)

        expect(subject.link).to include(expected_link)
      end
    end

    context 'when no security menu item and show promotions' do
      let(:user) { nil }

      it 'returns nil', :aggregate_failures do
        expect(subject.renderable_items).to be_empty
        expect(subject.link).to be_nil
      end
    end
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.find { |i| i.item_id == item_id } }

    describe 'Configuration' do
      let(:item_id) { :configuration }

      describe '#sidebar_security_configuration_paths' do
        let(:expected_security_configuration_paths) do
          %w[
            projects/security/configuration#show
            projects/security/sast_configuration#show
            projects/security/api_fuzzing_configuration#show
            projects/security/dast_configuration#show
            projects/security/dast_profiles#show
            projects/security/dast_site_profiles#new
            projects/security/dast_site_profiles#edit
            projects/security/dast_scanner_profiles#new
            projects/security/dast_scanner_profiles#edit
            projects/security/corpus_management#show
          ]
        end

        it 'includes all the security configuration paths' do
          expect(subject.active_routes[:path]).to match_array expected_security_configuration_paths
        end
      end
    end

    describe 'Discover Security and Compliance' do
      let(:item_id) { :discover_project_security }

      context 'when show_discover_project_security is true' do
        it { is_expected.not_to be_nil }
      end

      context 'when show_discover_project_security is not true' do
        let(:show_discover_project_security) { false }

        it { is_expected.to be_nil }
      end
    end

    describe 'Security Dashboard' do
      let(:item_id) { :dashboard }

      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user can access security dashboard' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access security dashboard' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Vulnerability Report' do
      let(:item_id) { :vulnerability_report }

      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user can access vulnerabilities report' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access vulnerabilities report' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'On Demand Scans' do
      let(:item_id) { :on_demand_scans }

      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when user can access vulnerabilities report' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access vulnerabilities report' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Dependency List' do
      let(:item_id) { :dependency_list }

      before do
        stub_licensed_features(dependency_scanning: true)
      end

      context 'when user can access dependency list' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access dependency list' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'License Compliance' do
      let(:item_id) { :license_compliance }

      before do
        stub_licensed_features(license_scanning: true)
      end

      context 'when user can access license compliance' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access license compliance' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Policies' do
      let(:item_id) { :scan_policies }

      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when user can access policies tab' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access policies tab' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Audit Events' do
      let(:item_id) { :audit_events }

      context 'when user can access audit events' do
        it { is_expected.not_to be_nil }

        context 'when feature audit events is licensed' do
          before do
            stub_licensed_features(audit_events: true)
          end

          it { is_expected.not_to be_nil }
        end

        context 'when feature audit events is not licensed' do
          before do
            stub_licensed_features(audit_events: false)
          end

          context 'when show promotions is enabled' do
            it { is_expected.not_to be_nil }
          end

          context 'when show promotions is disabled' do
            let(:show_promotions) { false }

            it { is_expected.to be_nil }
          end
        end
      end

      context 'when user cannot access audit events' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end
  end
end
