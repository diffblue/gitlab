# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::ExportSerializers::Sbom::PipelineService, feature_category: :dependency_management do
  let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report) }

  describe '.execute' do
    let(:dependency_list_export) { instance_double(Dependencies::DependencyListExport, pipeline: pipeline) }

    subject(:execute) { described_class.execute(dependency_list_export) }

    it 'instantiates a service object and sends execute message to it' do
      expect_next_instance_of(described_class, dependency_list_export) do |service_object|
        expect(service_object).to receive(:execute)
      end

      execute
    end
  end

  describe '#execute' do
    let(:dependency_list_export) { create(:dependency_list_export, exportable: pipeline) }

    let(:service_class) { described_class.new(dependency_list_export) }

    subject(:components) { service_class.execute.as_json[:components] }

    before do
      stub_licensed_features(dependency_scanning: true)
    end

    context 'when the pipeline does not have cyclonedx reports' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline) }

      it { is_expected.to be_empty }
    end

    context 'when the pipeline has cyclonedx reports' do
      it 'returns all the components' do
        expect(components.count).to be 441
      end
    end

    context 'when the merged report is not valid' do
      let(:invalid_report) do
        report = ::Gitlab::Ci::Reports::Sbom::Report.new
        report.sbom_attributes = { invalid: 'json' }
        report
      end

      before do
        allow_next_instance_of(::Sbom::MergeReportsService) do |service|
          allow(service).to receive(:execute).and_return(invalid_report)
        end
      end

      it 'raises a SchemaValidationError' do
        expect { service_class.execute }.to raise_error(
          described_class::SchemaValidationError
        ).with_message(/Invalid CycloneDX report: /)
      end
    end
  end
end
