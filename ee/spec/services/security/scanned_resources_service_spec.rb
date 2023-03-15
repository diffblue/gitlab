# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScannedResourcesService, '#execute', feature_category: :vulnerability_management do
  before do
    stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

  before_all do
    create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :dast, job: job, project: project)
    end
    create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :sast, job: job, project: project)
    end
  end

  context 'The pipeline has security builds' do
    context 'Report types are requested' do
      subject { described_class.new(pipeline, %w[sast dast]).execute }

      it 'only returns the requested scans' do
        expect(subject.keys).to contain_exactly('sast', 'dast')
      end

      it 'returns the scanned resources' do
        expect(subject['sast']).to be_empty
        expect(subject['dast'].length).to eq(6)
        expect(subject['dast']).to include(
          {
            'url' => 'http://api-server/',
            'request_method' => 'GET'
          }
        )
      end
    end
  end

  context 'A limited number of scanned resources are requested' do
    subject { described_class.new(pipeline, %w[dast], 2).execute }

    it 'returns the scanned resources' do
      expect(subject['dast'].length).to eq(2)
    end
  end

  context 'The Pipeline has no security builds' do
    let_it_be(:pipeline) { create(:ci_pipeline, :success) }

    subject { described_class.new(pipeline, %w[sast dast]).execute }

    it {
      is_expected.to match(
        a_hash_including('sast' => [], 'dast' => [])
      )
    }
  end

  context 'Pipeline is nil' do
    subject { described_class.new(nil, %w[sast dast]).execute }

    it {
      is_expected.to match(
        a_hash_including('sast' => [], 'dast' => [])
      )
    }
  end
end
