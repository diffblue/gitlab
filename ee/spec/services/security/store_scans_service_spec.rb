# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::StoreScansService do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  describe '.execute' do
    let(:mock_service_object) { instance_double(described_class, execute: true) }

    subject(:execute) { described_class.execute(pipeline) }

    before do
      allow(described_class).to receive(:new).with(pipeline).and_return(mock_service_object)
    end

    it 'delegates the call to an instance of `Security::StoreScansService`' do
      execute

      expect(described_class).to have_received(:new).with(pipeline)
      expect(mock_service_object).to have_received(:execute)
    end
  end

  describe '#execute' do
    let(:service_object) { described_class.new(pipeline) }

    let_it_be(:sast_build) { create(:ee_ci_build, pipeline: pipeline) }
    let_it_be(:dast_build) { create(:ee_ci_build, pipeline: pipeline) }
    let_it_be(:sast_artifact) { create(:ee_ci_job_artifact, :sast, job: sast_build) }
    let_it_be(:dast_artifact) { create(:ee_ci_job_artifact, :dast, job: dast_build) }

    subject(:store_group_of_artifacts) { service_object.execute }

    before do
      allow(StoreSecurityReportsWorker).to receive(:perform_async)
      allow(Security::StoreGroupedScansService).to receive(:execute)

      stub_licensed_features(sast: true, dast: false)
    end

    it 'executes Security::StoreGroupedScansService for each group of artifacts if the feature is available' do
      store_group_of_artifacts

      expect(Security::StoreGroupedScansService).to have_received(:execute).with([sast_artifact])
      expect(Security::StoreGroupedScansService).not_to have_received(:execute).with([dast_artifact])
    end

    context 'when the pipeline is for the default branch' do
      before do
        allow(pipeline).to receive(:default_branch?).and_return(true)
      end

      it 'schedules the `StoreSecurityReportsWorker`' do
        store_group_of_artifacts

        expect(StoreSecurityReportsWorker).to have_received(:perform_async).with(pipeline.id)
      end
    end

    context 'when the pipeline is not for the default branch' do
      before do
        allow(pipeline).to receive(:default_branch?).and_return(false)
      end

      it 'does not schedule the `StoreSecurityReportsWorker`' do
        store_group_of_artifacts

        expect(StoreSecurityReportsWorker).not_to have_received(:perform_async)
      end
    end
  end
end
