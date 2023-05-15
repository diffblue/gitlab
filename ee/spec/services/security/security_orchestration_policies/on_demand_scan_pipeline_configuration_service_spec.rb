# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService,
  feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project, :repository) }

    let_it_be(:site_profile) { create(:dast_site_profile, project: project) }
    let_it_be(:scanner_profile) { create(:dast_scanner_profile, project: project) }

    let(:service) { described_class.new(project) }
    let(:actions) do
      [
        {
          scan: 'dast',
          site_profile: site_profile.name,
          scanner_profile: scanner_profile.name,
          tags: ['runner-tag']
        },
        {
          scan: 'dast',
          site_profile: 'Site Profile B'
        }
      ]
    end

    subject(:pipeline_configuration) { service.execute(actions) }

    before do
      allow(DastSiteProfilesFinder).to receive(:new).and_return(double(execute: []))
      allow(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: site_profile.name).and_return(double(execute: [site_profile]))
      allow(DastScannerProfilesFinder).to receive(:new).and_return(double(execute: []))
      allow(DastScannerProfilesFinder).to receive(:new).with(project_ids: [project.id], name: scanner_profile.name).and_return(double(execute: [scanner_profile]))
    end

    it 'uses DastSiteProfilesFinder and DastScannerProfilesFinder to find DAST profiles within the project' do
      expect(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: site_profile.name)
      expect(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: 'Site Profile B')
      expect(DastScannerProfilesFinder).to receive(:new).with(project_ids: [project.id], name: scanner_profile.name)

      pipeline_configuration
    end

    it 'delegates params creation to DastOnDemandScans::ParamsCreateService' do
      expect(AppSec::Dast::ScanConfigs::BuildService).to receive(:new).with(container: project, params: { dast_site_profile: site_profile, dast_scanner_profile: scanner_profile }).and_call_original
      expect(AppSec::Dast::ScanConfigs::BuildService).to receive(:new).with(container: project, params: { dast_site_profile: nil, dast_scanner_profile: nil }).and_call_original

      pipeline_configuration
    end

    it 'fetches template content using ::TemplateFinder' do
      expect(::TemplateFinder).to receive(:build).with(:gitlab_ci_ymls, nil, name: 'DAST-On-Demand-Scan').and_call_original

      pipeline_configuration
    end

    it 'returns prepared CI configuration with DAST On-Demand scans defined' do
      expected_configuration = {
        'dast-on-demand-0': {
          stage: 'dast',
          tags: ['runner-tag'],
          image: { name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION' },
          variables: {
            DAST_VERSION: 4,
            SECURE_ANALYZERS_PREFIX: '$CI_TEMPLATE_REGISTRY_HOST/security-products',
            GIT_STRATEGY: 'none'
          },
          allow_failure: true,
          script: ['/analyze'],
          artifacts: { reports: { dast: 'gl-dast-report.json' } },
          dast_configuration: { site_profile: site_profile.name, scanner_profile: scanner_profile.name }
        },
        'dast-on-demand-1': {
          script: 'echo "Error during On-Demand Scan execution: Dast site profile was not provided" && false',
          allow_failure: true
        }
      }

      expect(pipeline_configuration).to eq(expected_configuration)
    end

    describe "variable injection and precedence" do
      let(:actions) do
        [
          {
            scan: 'dast',
            site_profile: site_profile.name,
            scanner_profile: scanner_profile.name,
            variables: { "DAST_VERSION" => "42" }
          }
        ]
      end

      subject(:variables) { pipeline_configuration.dig(:"dast-on-demand-0", :variables) }

      it "overrides template variables with action variables" do
        expect(variables).to include(DAST_VERSION: "42")
      end
    end
  end
end
