# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::LicenseScanning::BranchComponents, feature_category: :software_composition_analysis do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:branch) { project.repository.branches[2] }

  describe '#fetch' do
    subject(:branch_components) { described_class.new(project: project, branch_ref: branch.name) }

    it 'fetches the latest pipeline for the given ref with sbom reports' do
      expect(project).to receive(:latest_pipeline_with_reports_for_ref)
        .with(branch.name, ::Ci::JobArtifact.of_report_type(:sbom))

      branch_components.fetch
    end

    context 'when there is a pipeline with an sbom report' do
      let_it_be(:pipeline) do
        create(:ee_ci_pipeline, :with_cyclonedx_report, project: project, ref: branch.name, sha: branch.target)
      end

      it 'fetches components for the sbom pipeline' do
        expect_next_instance_of(Gitlab::LicenseScanning::PipelineComponents, pipeline: pipeline) do |instance|
          expect(instance).to receive(:fetch)
        end

        branch_components.fetch
      end
    end

    RSpec.shared_examples 'does not fetch pipeline components' do
      it do
        expect(Gitlab::LicenseScanning::PipelineComponents).not_to receive(:new)

        branch_components.fetch
      end
    end

    context 'when the pipeline does not have an sbom report' do
      let_it_be(:pipeline) do
        create(:ee_ci_pipeline, :with_dependency_scanning_report,
               project: project, ref: branch.name, sha: branch.target)
      end

      it_behaves_like 'does not fetch pipeline components'
    end

    context 'when the pipeline does not have any reports' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project, ref: branch.name, sha: branch.target) }

      it_behaves_like 'does not fetch pipeline components'
    end

    context 'when no pipeline exists for the given ref' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project) }

      it_behaves_like 'does not fetch pipeline components'
    end
  end
end
