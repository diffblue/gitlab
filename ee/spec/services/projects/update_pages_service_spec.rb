# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::UpdatePagesService do
  let(:group) { create(:group, :nested, max_pages_size: 200) }
  let(:project) { create(:project, :repository, namespace: group, max_pages_size: 250) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit('HEAD').sha) }
  let(:build) { create(:ci_build, pipeline: pipeline, ref: 'HEAD') }

  subject { described_class.new(project, build) }

  describe 'maximum pages artifacts size' do
    let(:metadata) { spy('metadata') }

    before do
      file = fixture_file_upload('spec/fixtures/pages.zip')
      metafile = fixture_file_upload('spec/fixtures/pages.zip.meta')

      create(:ci_job_artifact, :archive, :correct_checksum, file: file, job: build)
      create(:ci_job_artifact, :metadata, file: metafile, job: build)

      allow(build).to receive(:artifacts_metadata_entry)
                        .and_return(metadata)

      stub_licensed_features(pages_size_limit: true)
    end

    it_behaves_like 'pages size limit is', 250.megabytes

    it 'uses closest setting for max_pages_size' do
      allow(metadata).to receive(:total_size).and_return(1.megabyte)
      allow(metadata).to receive(:entries).and_return([])

      expect(project).to receive(:closest_setting).with(:max_pages_size).and_call_original

      subject.execute
    end

    context 'when pages_size_limit feature is not available' do
      before do
        stub_licensed_features(pages_size_limit: false)
      end

      it_behaves_like 'pages size limit is', 100.megabytes
    end
  end

  def deploy_status
    GenericCommitStatus.find_by(name: 'pages:deploy')
  end
end
