# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyAssociationsService do
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }

  let_it_be(:artifact_1, refind: true) { create(:ci_job_artifact, :zip, project: project_1) }
  let_it_be(:artifact_2, refind: true) { create(:ci_job_artifact, :zip, project: project_2) }
  let_it_be(:artifact_3, refind: true) { create(:ci_job_artifact, :zip, project: project_1) }

  let(:artifacts) { Ci::JobArtifact.where(id: [artifact_1.id, artifact_2.id, artifact_3.id]) }
  let(:service) { described_class.new(artifacts) }

  describe '#destroy_records' do
    it 'removes artifacts without updating statistics' do
      expect_next_instance_of(Ci::JobArtifacts::DestroyBatchService) do |service|
        expect(service).to receive(:execute).with(update_stats: false).and_call_original
      end

      expect { service.destroy_records }.to change { Ci::JobArtifact.count }.by(-3)
    end

    context 'when there are no artifacts' do
      let(:artifacts) { Ci::JobArtifact.none }

      it 'does not raise error' do
        expect { service.destroy_records }.not_to raise_error
      end
    end
  end

  describe '#update_statistics' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      service.destroy_records
    end

    it 'updates project statistics' do
      project1_increments = [
        have_attributes(amount: -artifact_1.size, ref: artifact_1.id),
        have_attributes(amount: -artifact_3.size, ref: artifact_3.id)
      ]
      project2_increments = [have_attributes(amount: -artifact_2.size, ref: artifact_2.id)]

      expect(ProjectStatistics).to receive(:bulk_increment_statistic).once
        .with(project_1, :build_artifacts_size, match_array(project1_increments))
      expect(ProjectStatistics).to receive(:bulk_increment_statistic).once
        .with(project_2, :build_artifacts_size, match_array(project2_increments))

      service.update_statistics
    end

    context 'when there are no artifacts' do
      let(:artifacts) { Ci::JobArtifact.none }

      it 'does not raise error' do
        expect { service.update_statistics }.not_to raise_error
      end
    end
  end
end
