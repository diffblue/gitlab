# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastSiteProfile'] do
  include GraphqlHelpers
  include RepoHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:object, reload: true) { create(:dast_site_profile, project: project) }
  let_it_be(:fields) { %i[id profileName targetUrl targetType editPath excludedUrls requestHeaders validationStatus userPermissions normalizedTargetUrl auth referencedInSecurityPolicies scanMethod scanFilePath validationStartedAt] }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class.graphql_name).to eq('DastSiteProfile') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::DastSiteProfile) }

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to have_graphql_field(:referenced_in_security_policies, calls_gitaly?: true) }

  describe 'id field' do
    it 'is the global id' do
      expect(resolve_field(:id, object, current_user: user)).to eq(object.to_global_id)
    end
  end

  describe 'profileName field' do
    it 'is the name' do
      expect(resolve_field(:profile_name, object, current_user: user)).to eq(object.name)
    end
  end

  describe 'targetUrl field' do
    it 'is the url of the associated dast_site' do
      expect(resolve_field(:target_url, object, current_user: user)).to eq(object.dast_site.url)
    end
  end

  describe 'targetType field' do
    it 'is the target type' do
      expect(resolve_field(:target_type, object, current_user: user)).to eq('website')
    end
  end

  describe 'editPath field' do
    it 'is the relative path to edit the dast_site_profile' do
      path = "/#{project.full_path}/-/security/configuration/profile_library/dast_site_profiles/#{object.id}/edit"

      expect(resolve_field(:edit_path, object, current_user: user)).to eq(path)
    end
  end

  describe 'auth field' do
    it 'is the dast_site_profile' do
      expect(resolve_field(:auth, object, current_user: user)).to eq(object)
    end
  end

  describe 'excludedUrls field' do
    it 'is the excluded urls' do
      expect(resolve_field(:excluded_urls, object, current_user: user)).to eq(object.excluded_urls)
    end
  end

  describe 'requestHeaders field' do
    context 'when there is no associated secret variable' do
      it 'is nil' do
        expect(resolve_field(:request_headers, object, current_user: user)).to be_nil
      end
    end

    context 'when there an associated secret variable' do
      it 'is redacted' do
        create(:dast_site_profile_secret_variable, :request_headers, dast_site_profile: object)

        expect(resolve_field(:request_headers, object, current_user: user)).to eq('••••••••')
      end
    end
  end

  describe 'validation_status field' do
    it 'is the validation status' do
      expect(resolve_field(:validation_status, object, current_user: user)).to eq('none')
    end
  end

  describe 'normalizedTargetUrl field' do
    it 'is the normalized url of the associated dast_site' do
      normalized_url = DastSiteValidation.get_normalized_url_base(object.dast_site.url)

      expect(resolve_field(:normalized_target_url, object, current_user: user)).to eq(normalized_url)
    end
  end

  describe 'referencedInSecurityPolicies field' do
    it 'is the lazy aggregate that is resolved to policies', :aggregate_failures do
      field_value = resolve_field(:referenced_in_security_policies, object, current_user: user)

      expect(field_value).to be_a(GraphQL::Execution::Lazy)
      expect(field_value.value).to eq(object.referenced_in_security_policies)
    end
  end

  describe 'scan_method field' do
    it 'is the scan method' do
      expect(resolve_field(:scan_method, object, current_user: user)).to eq('site')
    end
  end

  describe 'scan_file_path field' do
    let_it_be(:target_type) { 'api' }
    let_it_be(:scan_file_path) { 'https://www.domain.com/test-api-specification.json' }
    let_it_be(:object, reload: true) { create(:dast_site_profile, project: project, target_type: target_type, scan_file_path: scan_file_path) }

    it 'is the scan file path' do
      expect(resolve_field(:scan_file_path, object, current_user: user)).to eq(scan_file_path)
    end
  end

  describe 'dast_site_profiles' do
    subject(:response) do
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

    let(:query) do
      %(
        query project($fullPath: ID!) {
          project(fullPath: $fullPath) {
            dastSiteProfiles {
              nodes {
                id
                profileName
                referencedInSecurityPolicies
              }
            }
          }
        }
      )
    end

    context 'when security policies are enabled' do
      let_it_be(:policies_project) { create(:project, :repository) }
      let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: policies_project) }

      let(:policy1) do
        build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: %w[master] }], actions: [
                { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' },
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
        create_list(:dast_site_profile, 30, project: project)
        create_file_in_repo(policies_project, 'master', 'master', Security::OrchestrationPolicyConfiguration::POLICY_PATH, policy_yaml)
      end

      it 'only calls Gitaly twice when multiple profiles are present', :request_store do
        expect { response }.to change { Gitlab::GitalyClient.get_request_count }.by(2)
      end
    end
  end

  describe 'validation_started_at field' do
    context 'when dast_site_validation association does not exist' do
      it 'is the validation_started_at' do
        expect(resolve_field(:validation_started_at, object, current_user: user)).to be_nil
      end
    end

    context 'when dast_site_validation association does exist' do
      let(:validation_started_at) { Time.new(2022).utc }
      let(:dast_site_token) { create(:dast_site_token, project: project) }
      let(:dast_site_validation) { create(:dast_site_validation, validation_started_at: validation_started_at, dast_site_token: dast_site_token) }

      before do
        object.dast_site.update!(dast_site_validation_id: dast_site_validation.id)
      end

      it 'is the validation_started_at' do
        expect(resolve_field(:validation_started_at, object, current_user: user)).to eq(dast_site_validation.validation_started_at)
      end
    end
  end
end
