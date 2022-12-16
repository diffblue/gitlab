# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::LicenseScanning::PipelineComponents, feature_category: :license_compliance do
  let_it_be(:project) { create(:project, :repository) }

  describe '#fetch' do
    subject(:pipeline_components) { described_class.new(pipeline: pipeline) }

    context 'when the pipeline has an sbom report' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

      it 'returns a list with the expected size' do
        expected_number_of_components = pipeline.sbom_reports.reports.sum { |report| report.components.length }
        expect(pipeline_components.fetch.count).to eql(expected_number_of_components)
      end

      it 'returns a list containing the expected elements' do
        expect(pipeline_components.fetch).to include(
          { name: "github.com/astaxie/beego", purl_type: "golang", version: "v1.10.0" },
          { name: "istanbul-lib-report", purl_type: "npm", version: "1.1.3" },
          { name: "yargs-parser", purl_type: "npm", version: "9.0.2" }
        )
      end
    end

    context 'when the pipeline does not have an sbom report' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }

      it 'returns an empty list' do
        expect(pipeline_components.fetch).to be_empty
      end
    end

    context 'when the pipeline does not have any reports' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project) }

      it 'returns an empty list' do
        expect(pipeline_components.fetch).to be_empty
      end
    end
  end
end
