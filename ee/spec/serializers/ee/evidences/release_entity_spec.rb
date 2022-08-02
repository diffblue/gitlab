# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::ReleaseEntity do
  let(:project) { build_stubbed(:project, :repository) }
  let(:release) { build_stubbed(:release, project: project) }

  context 'when report artifacts are passed' do
    let(:pipeline) { build_stubbed(:ci_empty_pipeline, sha: release.sha, project: project) }
    let(:build_test_report) { build_stubbed(:ci_build, :test_reports, :with_artifacts_paths, pipeline: pipeline) }
    let(:build_coverage_report) do
      build_stubbed(:ci_build, :coverage_reports, :with_artifacts_paths, pipeline: pipeline)
    end

    subject { described_class.new(release, report_artifacts: [build_test_report, build_coverage_report]).as_json }

    it 'has no report_artifacts if feature is unlicenced' do
      stub_licensed_features(release_evidence_test_artifacts: false)

      expect(subject).not_to have_key(:report_artifacts)
    end

    it 'exposes build artifacts if feature is licenced' do
      stub_licensed_features(release_evidence_test_artifacts: true)

      expect(subject[:report_artifacts]).to(
        contain_exactly(
          Evidences::BuildArtifactEntity.new(build_test_report).as_json,
          Evidences::BuildArtifactEntity.new(build_coverage_report).as_json
        )
      )
    end
  end
end
