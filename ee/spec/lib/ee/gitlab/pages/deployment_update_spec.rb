# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Pages::DeploymentUpdate do
  let(:group) { create(:group, :nested, max_pages_size: 200) }
  let(:project) { create(:project, :repository, namespace: group, max_pages_size: 250) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }
  let(:build) { create(:ci_build, pipeline: pipeline, ref: 'HEAD') }

  subject { described_class.new(project, build) }

  describe 'maximum pages artifacts size' do
    let(:metadata) { spy('metadata') } # rubocop: disable RSpec/VerifiedDoubles

    before do
      file = fixture_file_upload('spec/fixtures/pages.zip')
      metafile = fixture_file_upload('spec/fixtures/pages.zip.meta')

      create(:ci_job_artifact, :archive, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, :metadata, file: metafile, job: build)

      allow(build)
        .to receive(:artifacts_metadata_entry)
        .and_return(metadata)

      stub_licensed_features(pages_size_limit: true)
    end

    context "when size is below the limit" do
      before do
        allow(metadata).to receive(:total_size).and_return(249.megabyte)
        allow(metadata).to receive(:entries).and_return([])
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context "when size is above the limit" do
      before do
        allow(metadata).to receive(:total_size).and_return(251.megabyte)
        allow(metadata).to receive(:entries).and_return([])
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include('artifacts for pages are too large: 263192576')
      end
    end

    context 'when pages_size_limit feature is not available' do
      before do
        stub_licensed_features(pages_size_limit: false)
      end

      context "when size is below the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(99.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        it 'is valid' do
          expect(subject).to be_valid
        end
      end

      context "when size is above the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(101.megabyte)
          allow(metadata).to receive(:entries).and_return([])
        end

        it 'is invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to include('artifacts for pages are too large: 105906176')
        end
      end
    end
  end
end
