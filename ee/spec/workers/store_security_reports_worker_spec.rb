# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StoreSecurityReportsWorker do
  let_it_be(:secret_detection_scan_1) { create(:security_scan, scan_type: :secret_detection) }
  let_it_be(:secret_detection_scan_2) { create(:security_scan, scan_type: :secret_detection) }
  let_it_be(:secret_detection_pipeline) { secret_detection_scan_2.pipeline }

  describe '#secret_detection_vulnerability_found?' do
    before do
      finding = create(:vulnerabilities_finding, :with_secret_detection, project: secret_detection_pipeline.project)
      create(:vulnerabilities_finding_pipeline, finding: finding, pipeline: secret_detection_pipeline)
    end

    specify { expect(described_class.new.send(:secret_detection_vulnerability_found?, secret_detection_pipeline)).to be(true) }
  end

  describe '#revoke_secret_detection_token?' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility, :token_revocation_enabled, :secret_detection_vulnerability_found) do
      booleans = [true, true, false, false].permutation(2).to_a.uniq
      [:public, :private, nil].flat_map do |vis|
        booleans.map { |bools| [vis, *bools] }
      end
    end

    with_them do
      let(:pipeline) { build(:ee_ci_pipeline, project: build(:project, :repository, visibility)) if visibility }
      let(:expected_result) { [visibility, token_revocation_enabled, secret_detection_vulnerability_found] == [:public, true, true] }

      before do
        stub_application_setting(secret_detection_token_revocation_enabled: token_revocation_enabled)

        allow_next_instance_of(described_class) do |store_scans_worker|
          allow(store_scans_worker).to receive(:secret_detection_vulnerability_found?) { secret_detection_vulnerability_found }
        end
      end

      specify { expect(described_class.new.send(:revoke_secret_detection_token?, pipeline)).to eql(expected_result) }
    end
  end

  describe '#perform' do
    let(:group)   { create(:group) }
    let(:project) { create(:project, namespace: group) }
    let(:pipeline) { create(:ee_ci_pipeline, ref: 'master', project: project) }

    before do
      allow(::ScanSecurityReportSecretsWorker).to receive(:perform_async).and_return(nil)
      allow_next_instance_of(described_class) do |store_scans_worker|
        allow(store_scans_worker).to receive(:revoke_secret_detection_token?) { true }
      end
    end

    context 'when there is no pipeline with the given ID' do
      subject(:perform) { described_class.new.perform(0) }

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when at least one security report feature is enabled' do
      where(report_type: [:sast, :dast, :dependency_scanning, :container_scanning, :cluster_image_scanning])

      with_them do
        before do
          stub_licensed_features(report_type => true)
        end

        it 'scans security reports for token revocation' do
          expect(::ScanSecurityReportSecretsWorker).to receive(:perform_async)

          described_class.new.perform(pipeline.id)
        end

        it 'executes IngestReportsService for given pipeline' do
          expect(::Security::Ingestion::IngestReportsService).to receive(:execute).with(pipeline)

          described_class.new.perform(pipeline.id)
        end
      end
    end

    context 'when running SAST analyzers that produce duplicate vulnerabilities' do
      where(vulnerability_finding_signatures_enabled: [true, false])
      with_them do
        context 'and prefers original analyzer over semgrep when deduplicating' do
          let(:artifact_bandit1) { create(:ee_ci_job_artifact, :sast_bandit, job: bandit1_build) }
          let(:bandit1_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline, project: project) }

          let(:artifact_bandit2) { create(:ee_ci_job_artifact, :sast_bandit, job: bandit2_build) }
          let(:artifact_semgrep) { create(:ee_ci_job_artifact, :sast_semgrep_for_bandit, job: semgrep_build) }
          let(:pipeline2) { create(:ee_ci_pipeline, ref: 'master', project: project) }
          let(:bandit2_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline2, project: project) }
          let(:semgrep_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline2, project: project) }

          before do
            stub_licensed_features(
              sast: true,
              vulnerability_finding_signatures: vulnerability_finding_signatures_enabled
            )
            pipeline.update!(user: bandit1_build.user)
            pipeline2.update!(user: bandit2_build.user)
          end

          it 'does not duplicate vulnerabilities' do
            expect do
              Security::StoreGroupedScansService.execute([artifact_bandit1])
            end.to change { Security::Finding.count }.by(1)
              .and change { Security::Scan.count }.by(1)

            expect do
              described_class.new.perform(pipeline.id)
            end.to change { Vulnerabilities::Finding.count }.by(1)
              .and change { Vulnerability.count }.by(1)

            expect do
              Security::StoreGroupedScansService.execute([artifact_bandit2, artifact_semgrep])
            end.to change { Security::Finding.count }.by(2)
              .and change { Security::Scan.count }.by(2)

            expect do
              described_class.new.perform(pipeline2.id)
            end.to change { Vulnerabilities::Finding.count }.by(0)
              .and change { Vulnerability.count }.by(0)
          end
        end

        context 'and prefers semgrep over original analyzer when deduplicating' do
          let(:artifact_gosec1) { create(:ee_ci_job_artifact, :sast_gosec, job: gosec1_build) }
          let(:gosec1_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline, project: project) }

          let(:artifact_gosec2) { create(:ee_ci_job_artifact, :sast_gosec, job: gosec2_build) }
          let(:artifact_semgrep) { create(:ee_ci_job_artifact, :sast_semgrep_for_gosec, job: semgrep_build) }
          let(:pipeline2) { create(:ee_ci_pipeline, ref: 'master', project: project) }
          let(:gosec2_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline2, project: project) }
          let(:semgrep_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline2, project: project) }

          before do
            stub_licensed_features(
              sast: true,
              vulnerability_finding_signatures: vulnerability_finding_signatures_enabled
            )
            pipeline.update!(user: gosec1_build.user)
            pipeline2.update!(user: gosec2_build.user)
          end

          it 'does not duplicate vulnerabilities' do
            expect do
              Security::StoreGroupedScansService.execute([artifact_gosec1])
            end.to change { Security::Finding.count }.by(1)
              .and change { Security::Scan.count }.by(1)

            expect do
              described_class.new.perform(pipeline.id)
            end.to change { Vulnerabilities::Finding.count }.by(1)
              .and change { Vulnerability.count }.by(1)

            expect do
              Security::StoreGroupedScansService.execute([artifact_gosec2, artifact_semgrep])
            end.to change { Security::Finding.count }.by(2)
              .and change { Security::Scan.count }.by(2)

            expect do
              described_class.new.perform(pipeline2.id)
            end.to change { Vulnerabilities::Finding.count }.by(0)
              .and change { Vulnerability.count }.by(0)
          end
        end
      end
    end

    context 'when resolving dropped identifiers', :sidekiq_inline do
      let(:artifact_semgrep1) { create(:ee_ci_job_artifact, :sast_semgrep_for_multiple_findings, job: semgrep1_build) }
      let(:semgrep1_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline, project: project) }

      let(:pipeline2) { create(:ee_ci_pipeline, ref: 'master', project: project) }
      let(:artifact_semgrep2) { create(:ee_ci_job_artifact, :sast_semgrep_for_gosec, job: semgrep2_build) }
      let(:semgrep2_build) { create(:ci_build, :sast, :success, user: project.creator, pipeline: pipeline2, project: project) }

      before do
        stub_licensed_features(
          sast: true
        )
        stub_feature_flags(sec_mark_dropped_findings_as_resolved: true)
        pipeline.update!(user: semgrep1_build.user)
        pipeline2.update!(user: semgrep2_build.user)
      end

      it 'resolves vulnerabilities' do
        expect do
          Security::StoreGroupedScansService.execute([artifact_semgrep1])
        end.to change { Security::Finding.count }.by(2)
          .and change { Security::Scan.count }.by(1)

        expect do
          described_class.new.perform(pipeline.id)
        end.to change { Vulnerabilities::Finding.count }.by(2)
          .and change { Vulnerability.count }.by(2)
          .and change { project.vulnerabilities.with_resolution(false).count }.by(2)
          .and change { project.vulnerabilities.with_states(%w[detected]).count }.by(2)

        expect do
          Security::StoreGroupedScansService.execute([artifact_semgrep2])
        end.to change { Security::Finding.count }.by(1)
          .and change { Security::Scan.count }.by(1)

        expect do
          described_class.new.perform(pipeline2.id)
        end.to change { Vulnerabilities::Finding.count }.by(0)
          .and change { Vulnerability.count }.by(0)
          .and change { project.vulnerabilities.with_resolution(true).count }.by(1)
          .and change { project.vulnerabilities.with_states(%w[detected]).count }.by(-1)
          .and change { project.vulnerabilities.with_states(%w[resolved]).count }.by(1)
      end
    end

    context "when security reports feature is not available" do
      let(:default_branch) { pipeline.ref }

      it 'does not execute IngestReportsService' do
        expect(::Security::Ingestion::IngestReportsService).not_to receive(:execute)

        described_class.new.perform(pipeline.id)
      end
    end
  end
end
