# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Replication::JobArtifactRetriever, :geo do
  describe '#execute' do
    let(:retriever) { described_class.new(job_artifact.id, {}) }

    subject { retriever.execute }

    context 'when the job artifact exists' do
      before do
        expect(::Ci::JobArtifact).to receive(:find_by).with({ id: job_artifact.id }).and_return(job_artifact)
      end

      context 'when the job artifact is an archive file_type and has a file' do
        let(:job_artifact) { create(:ci_job_artifact, :archive) }

        it 'returns the file in a success hash' do
          expect(subject).to eq(code: :ok, message: 'Success', file: job_artifact.file)
        end
      end

      context 'when the job artifact is an metadata file_type and has a file' do
        let(:job_artifact) { create(:ci_job_artifact, :metadata) }

        it 'returns the file in a success hash' do
          expect(subject).to eq(code: :ok, message: 'Success', file: job_artifact.file)
        end
      end

      context 'when the job artifact does not have a file' do
        let(:job_artifact) { create(:ci_job_artifact) }

        it 'returns an error hash' do
          expect(subject).to include(code: :not_found, geo_code: 'FILE_NOT_FOUND', message: match(/JobArtifact #\d+ file not found/))
        end

        it 'logs the missing file' do
          expect(retriever).to receive(:log_error).with("Could not upload job artifact because it does not have a file", { id: job_artifact.id })

          subject
        end
      end
    end

    context 'when the job artifact does not exist' do
      let(:job_artifact) { double(id: 10000) }

      it 'returns an error hash' do
        expect(subject).to eq(code: :not_found, message: "Job artifact not found")
      end
    end
  end
end
