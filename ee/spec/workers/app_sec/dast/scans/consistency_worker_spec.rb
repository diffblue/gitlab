# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Scans::ConsistencyWorker, feature_category: :dynamic_application_security_testing do
  let(:worker) { described_class.new }

  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:profile) { create(:dast_profile, project: project) }

    let(:job_args) { [pipeline.id, profile.id] }

    it 'ensures cross database association is created', :aggregate_failures do
      expect { worker.perform(*job_args) }.to change { Dast::ProfilesPipeline.count }.by(1)

      expect(Dast::ProfilesPipeline.where(ci_pipeline_id: pipeline.id, dast_profile_id: profile.id)).to exist
    end

    it_behaves_like 'an idempotent worker'
  end
end
