# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestFindingPipelines, feature_category: :vulnerability_management do
  describe '#execute' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:finding) { create(:vulnerabilities_finding) }
    let(:finding_maps) { create_list(:finding_map, 1, finding: finding) }
    let(:service_object) { described_class.new(pipeline, finding_maps) }

    subject(:ingest_finding_pipelines) { service_object.execute }

    it 'associates the findings with pipeline' do
      expect { ingest_finding_pipelines }.to change { finding.finding_pipelines.pluck(:pipeline_id) }.from([]).to([pipeline.id])
    end

    it_behaves_like 'bulk insertable task'
  end
end
