# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::CreateEvidenceService, feature_category: :release_evidence do
  include Gitlab::Routing

  let(:project) { create(:project) }
  let(:release) { create(:release, project: project) }

  context 'when pipeline with artifacts is passed' do
    let(:pipeline) { create(:ci_empty_pipeline, sha: release.sha, project: project) }
    let!(:build_with_artifacts) { create(:ci_build, :artifacts, pipeline: pipeline) }
    let!(:build_test_report) { create(:ci_build, :test_reports, :with_artifacts_paths, pipeline: pipeline) }
    let!(:build_coverage_report) { create(:ci_build, :coverage_reports, :with_artifacts_paths, pipeline: pipeline) }

    let(:service) { described_class.new(release, pipeline: pipeline) }

    it 'includes test reports in evidence if feature is licenced' do
      stub_licensed_features(release_evidence_test_artifacts: true)

      service.execute

      evidence = Releases::Evidence.last
      evidence_reports = evidence.summary.dig('release', 'report_artifacts')
                           .map { |artifact| artifact['url'] }

      expect(evidence_reports).to(
        contain_exactly(
          download_project_job_artifacts_url(project, build_test_report),
          download_project_job_artifacts_url(project, build_coverage_report)
        )
      )
    end

    it 'includes test reports in evidence if feature is unlincenced' do
      stub_licensed_features(release_evidence_test_artifacts: false)

      service.execute
      expect(Releases::Evidence.last.summary['release']).not_to have_key('report_artifacts')
    end

    it 'keeps build report artifacts if feature is licenced' do
      stub_licensed_features(release_evidence_test_artifacts: true)

      Ci::Build.update_all(artifacts_expire_at: 1.month.from_now)

      service.execute

      expect(build_with_artifacts.reload.artifacts_expire_at).to be_present
      expect(build_test_report.reload.artifacts_expire_at).to be_nil
      expect(build_coverage_report.reload.artifacts_expire_at).to be_nil
    end

    it 'does not keep artifacts if feature is unlicenced' do
      stub_licensed_features(release_evidence_test_artifacts: false)

      Ci::Build.update_all(artifacts_expire_at: 1.month.from_now)

      service.execute

      expect(build_with_artifacts.reload.artifacts_expire_at).to be_present
      expect(build_test_report.reload.artifacts_expire_at).to be_present
      expect(build_coverage_report.reload.artifacts_expire_at).to be_present
    end
  end
end
