# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastScannerProfile'], :dynamic_analysis,
                                                                feature_category: :dynamic_application_security_testing do
  include RepoHelpers

  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile) }
  let_it_be(:project) { dast_scanner_profile.project }
  let_it_be(:user) { create(:user) }
  let_it_be(:fields) { %i[id profileName spiderTimeout targetTimeout editPath scanType useAjaxSpider showDebugMessages referencedInSecurityPolicies tagList] }

  let(:response) do
    GitlabSchema.execute(
      query,
      context: {
        current_user: user
      },
      variables: {
        fullPath: project.full_path
      }
    ).as_json
  end

  subject { response }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class.graphql_name).to eq('DastScannerProfile') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'dast_scanner_profiles' do
    before do
      project.add_developer(user)
    end

    let(:query) do
      %(
        query project($fullPath: ID!) {
          project(fullPath: $fullPath) {
            dastScannerProfiles {
              nodes {
                id
                profileName
                targetTimeout
                spiderTimeout
                scanType
                useAjaxSpider
                showDebugMessages
                referencedInSecurityPolicies
              }
            }
          }
        }
      )
    end

    let(:first_dast_scanner_profile) do
      response.dig('data', 'project', 'dastScannerProfiles', 'nodes', 0)
    end

    describe 'profile_name field' do
      subject { first_dast_scanner_profile['profileName'] }

      it { is_expected.to eq(dast_scanner_profile.name) }
    end

    context 'when security policies are enabled' do
      let_it_be(:policies_project) { create(:project, :repository) }
      let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: policies_project) }

      let(:policy1) do
        build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: %w[master] }], actions: [
                { scan: 'dast', site_profile: 'Site Profile', scanner_profile: dast_scanner_profile.name },
                { scan: 'dast', site_profile: 'Site Profile 2', scanner_profile: 'Scanner Profile 2' }
              ])
      end

      let(:policy2) do
        build(:scan_execution_policy, name: 'Run DAST in every pipeline 2', rules: [{ type: 'pipeline', branches: %w[master] }], actions: [
                { scan: 'dast', site_profile: 'Site Profile 3', scanner_profile: 'Scanner Profile 3' },
                { scan: 'dast', site_profile: 'Site Profile 4', scanner_profile: 'Scanner Profile 4' }
              ])
      end

      let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy1, policy2]) }

      before do
        create_list(:dast_scanner_profile, 30, project: project)
        create_file_in_repo(policies_project, 'master', 'master', Security::OrchestrationPolicyConfiguration::POLICY_PATH, policy_yaml)
      end

      it 'only calls Gitaly twice when multiple profiles are present', :request_store do
        expect { response }.to change { Gitlab::GitalyClient.get_request_count }.by(2)
      end
    end
  end
end
