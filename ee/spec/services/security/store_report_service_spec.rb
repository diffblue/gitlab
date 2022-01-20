# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::StoreReportService, '#execute', :snowplow do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  let(:artifact) { create(:ee_ci_job_artifact, trait) }
  let(:report_type) { artifact.file_type }
  let(:project) { artifact.project }
  let(:pipeline) { artifact.job.pipeline }
  let(:report) { pipeline.security_reports.get_report(report_type.to_s, artifact) }

  subject(:store_report) { described_class.new(pipeline, report).execute }

  where(:vulnerability_finding_signatures) do
    [true, false]
  end

  with_them do
    before do
      stub_licensed_features(
        sast: true,
        dependency_scanning: true,
        container_scanning: true,
        security_dashboard: true,
        sast_fp_reduction: true,
        vulnerability_finding_signatures: vulnerability_finding_signatures
      )
      allow(Security::AutoFixWorker).to receive(:perform_async)
    end

    context 'without existing data' do
      before(:all) do
        checksum = 'f00bc6261fa512f0960b7fc3bfcce7fb31997cf32b96fa647bed5668b2c77fee'
        create(:vulnerabilities_remediation, checksum: checksum)
      end

      before do
        project.add_developer(user)
        allow(pipeline).to receive(:user).and_return(user)
      end

      context 'for different security reports' do
        where(:case_name, :trait, :scanners, :identifiers, :findings, :finding_identifiers, :finding_pipelines, :remediations, :signatures, :finding_links, :finding_flags) do
          'with SAST report'                | :sast                            | 1 | 6  | 5 | 7  | 5  | 0 | 2 | 2 | 0
          'with exceeding identifiers'      | :with_exceeding_identifiers      | 1 | 20 | 1 | 20 | 1  | 0 | 0 | 0 | 0
          'with Dependency Scanning report' | :dependency_scanning_remediation | 1 | 3  | 2 | 3  | 2  | 1 | 0 | 6 | 0
          'with Container Scanning report'  | :container_scanning              | 1 | 8  | 8 | 8  | 8  | 0 | 0 | 8 | 0
          'with vulnerability flags'        | :sast_with_vulnerability_flags   | 1 | 6  | 5 | 7  | 5  | 0 | 2 | 0 | 2
        end

        with_them do
          it 'inserts all scanners' do
            expect { subject }.to change { Vulnerabilities::Scanner.count }.by(scanners)
          end

          it 'inserts all identifiers' do
            expect { subject }.to change { Vulnerabilities::Identifier.count }.by(identifiers)
          end

          it 'inserts all findings' do
            expect { subject }.to change { Vulnerabilities::Finding.count }.by(findings)
          end

          context 'vulnerability flags' do
            it 'inserts all finding flags' do
              expect { subject }.to change { Vulnerabilities::Flag.count }.by(finding_flags)
            end

            it 'tracks the snowplow event' do
              subject

              if case_name == 'with vulnerability flags'
                expect_snowplow_event(
                  category: 'Security::StoreReportService',
                  action: 'flag_vulnerability',
                  label: 'false_positive'
                )
              end
            end
          end

          it 'inserts all finding links' do
            expect { subject }.to change { Vulnerabilities::FindingLink.count }.by(finding_links)
          end

          context 'when finding links creation is disabled' do
            before do
              stub_feature_flags(vulnerability_finding_replace_metadata: false)
            end

            it 'does not insert finding links' do
              expect { subject }.not_to change { Vulnerabilities::FindingLink.count }
            end
          end

          it 'inserts all finding identifiers (join model)' do
            expect { subject }.to change { Vulnerabilities::FindingIdentifier.count }.by(finding_identifiers)
          end

          it 'inserts all finding pipelines (join model)' do
            expect { subject }.to change { Vulnerabilities::FindingPipeline.count }.by(finding_pipelines)
          end

          it 'inserts all remediations' do
            expect { subject }.to change { project.vulnerability_remediations.count }.by(remediations)
          end

          it 'inserts all vulnerabilities' do
            expect { subject }.to change { Vulnerability.count }.by(findings)
          end

          it 'inserts all signatures' do
            signatures_count = vulnerability_finding_signatures ? signatures : 0
            expect { subject }.to change { Vulnerabilities::FindingSignature.count }.by(signatures_count)
          end
        end
      end

      context 'when there is an exception' do
        let(:trait) { :sast }

        subject { described_class.new(pipeline, report) }

        it 'does not insert any scanner' do
          allow(Vulnerabilities::Scanner).to receive(:insert_all).with(anything).and_raise(StandardError)
          expect { subject.send(:update_vulnerability_scanners!, report.findings) }.to change { Vulnerabilities::Scanner.count }.by(0)
        end
      end

      context 'when some attributes are missing in the identifiers' do
        let(:trait) { :sast }
        let(:other_params) {{ external_type: 'find_sec_bugs_type', external_id: 'PREDICTABLE_RANDOM', name: 'Find Security Bugs-PREDICTABLE_RANDOM', url: 'https://find-sec-bugs.github.io/bugs.htm#PREDICTABLE_RANDOM', created_at: Time.current, updated_at: Time.current }}
        let(:record_1) {{ id: 4, project_id: 2, fingerprint: '5848739446034d982ef7beece3bb19bff4044ffb', **other_params }}
        let(:record_2) {{ project_id: 2, fingerprint: '5848739446034d982ef7beece3bb19bff4044ffb', **other_params }}
        let(:record_3) {{ id: 4, fingerprint: '5848739446034d982ef7beece3bb19bff4044ffb', **other_params }}
        let(:record_4) {{ id: 5, fingerprint: '6848739446034d982ef7beece3bb19bff4044ffb', **other_params }}
        let(:record_5) {{ fingerprint: '5848739446034d982ef7beece3bb19bff4044ffb', **other_params }}
        let(:record_6) {{ fingerprint: '6848739446034d982ef7beece3bb19bff4044ffb', **other_params }}

        subject { described_class.new(pipeline, report) }

        it 'updates existing vulnerability identifiers in groups' do
          expect(Vulnerabilities::Identifier).to receive(:upsert_all).with([record_1])
          expect(Vulnerabilities::Identifier).to receive(:upsert_all).with([record_3, record_4])

          subject.send(:update_existing_vulnerability_identifiers_for, [record_1, record_3, record_4])
        end

        it 'does not update any identifier for an empty list of records' do
          expect(Vulnerabilities::Identifier).not_to receive(:upsert_all)

          subject.send(:update_existing_vulnerability_identifiers_for, [])
        end

        it 'inserts new vulnerability identifiers in groups' do
          expect(Vulnerabilities::Identifier).to receive(:insert_all).with([record_2])
          expect(Vulnerabilities::Identifier).to receive(:insert_all).with([record_5, record_6])

          subject.send(:insert_new_vulnerability_identifiers_for, [record_2, record_5, record_6])
        end

        it 'does not insert any identifier for an empty list of records' do
          expect(Vulnerabilities::Identifier).not_to receive(:insert_all)

          subject.send(:insert_new_vulnerability_identifiers_for, [])
        end
      end

      context 'when N+1 database queries have been removed' do
        let(:trait) { :sast }
        let(:bandit_scanner) { build(:ci_reports_security_scanner, external_id: 'bandit', name: 'Bandit') }
        let(:link) { build(:ci_reports_security_link) }
        let(:bandit_finding) { build(:ci_reports_security_finding, scanner: bandit_scanner, links: [link]) }
        let(:vulnerability_findings) { [] }

        subject { described_class.new(pipeline, report) }

        it "avoids N+1 database queries for updating vulnerability scanners", :use_sql_query_cache do
          report.add_scanner(bandit_scanner)

          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { subject.send(:update_vulnerability_scanners!, report.findings) }.count

          2.times { add_finding_to_report }

          expect { subject.send(:update_vulnerability_scanners!, report.findings) }.not_to exceed_query_limit(control_count)
        end

        it "avoids N+1 database queries for updating finding_links", :use_sql_query_cache do
          report.add_scanner(bandit_scanner)
          add_finding_to_report

          stub_vulnerability_finding_id_to_finding_map
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { subject.send(:update_vulnerability_links_info) }.count

          2.times { add_finding_to_report }

          stub_vulnerability_finding_id_to_finding_map
          expect { subject.send(:update_vulnerability_links_info) }.not_to exceed_query_limit(control_count)
        end

        it "avoids N+1 database queries for updating vulnerabilities_identifiers", :use_sql_query_cache do
          report.add_scanner(bandit_scanner)
          add_finding_to_report

          stub_vulnerability_finding_id_to_finding_map
          stub_vulnerability_findings
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { subject.send(:update_vulnerabilities_identifiers) }.count

          2.times { add_finding_to_report }

          stub_vulnerability_finding_id_to_finding_map
          stub_vulnerability_findings
          expect { subject.send(:update_vulnerabilities_identifiers) }.not_to exceed_query_limit(control_count)
        end

        def add_finding_to_report
          report.add_finding(bandit_finding)
        end

        def stub_vulnerability_findings
          allow(subject).to receive(:vulnerability_findings)
            .and_return(vulnerability_findings)
        end

        def stub_vulnerability_finding_id_to_finding_map
          allow(subject).to receive(:vulnerability_finding_id_to_finding_map)
            .and_return(vulnerability_finding_id_to_finding_map)
        end

        def vulnerability_finding_id_to_finding_map
          vulnerability_findings.clear
          report.findings.to_h do |finding|
            vulnerability_finding = create(:vulnerabilities_finding)
            vulnerability_findings << vulnerability_finding
            [vulnerability_finding.id, finding]
          end
        end
      end

      context 'when report data includes all raw_metadata' do
        let(:trait) { :dependency_scanning_remediation }

        it 'inserts top level finding data', :aggregate_failures do
          subject

          finding = Vulnerabilities::Finding.last
          finding.raw_metadata = nil

          expect(finding.metadata).to be_blank
          expect(finding.cve).not_to be_nil
          expect(finding.description).not_to be_nil
          expect(finding.location).not_to be_nil
          expect(finding.message).not_to be_nil
          expect(finding.solution).not_to be_nil
        end
      end

      context 'invalid data' do
        let(:artifact) { create(:ee_ci_job_artifact, :sast) }
        let(:finding_without_name) { build(:ci_reports_security_finding, name: nil) }
        let(:report) { Gitlab::Ci::Reports::Security::Report.new('container_scanning', nil, nil) }

        before do
          allow(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original
          report.add_finding(finding_without_name)
        end

        it 'does not raise any exception' do
          expect { store_report }.not_to raise_error
        end

        it 'reports the error to sentry' do
          store_report

          expected_params = finding_without_name.to_hash.dig(:raw_metadata)
          expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(an_instance_of(ActiveRecord::RecordInvalid), create_params: expected_params)
        end
      end
    end

    context 'with existing data from previous pipeline' do
      let(:finding_identifier_fingerprint) do
        build(:ci_reports_security_identifier, external_id: "CIPHER_INTEGRITY").fingerprint
      end

      let(:scanner) { build(:vulnerabilities_scanner, project: project, external_id: 'find_sec_bugs', name: 'Find Security Bugs') }
      let(:identifier) { build(:vulnerabilities_identifier, project: project, fingerprint: finding_identifier_fingerprint) }
      let(:different_identifier) { build(:vulnerabilities_identifier, project: project) }
      let!(:new_artifact) { create(:ee_ci_job_artifact, :sast, job: new_build) }
      let(:new_build) { create(:ci_build, pipeline: new_pipeline) }
      let(:new_pipeline) { create(:ci_pipeline, project: project) }
      let(:new_report) { new_pipeline.security_reports.get_report(report_type.to_s, artifact) }
      let(:existing_signature) { create(:vulnerabilities_finding_signature, finding: finding) }

      let(:trait) { :sast }

      let(:finding_location_fingerprint) do
        build(
          :ci_reports_security_locations_sast,
          file_path: "groovy/src/main/java/com/gitlab/security_products/tests/App.groovy",
          start_line: "29",
          end_line: "29"
        ).fingerprint
      end

      let!(:finding) do
        created_finding = create(:vulnerabilities_finding,
          identifiers: [identifier],
          primary_identifier: identifier,
          scanner: scanner,
          project: project,
          uuid: "e5388f40-18f5-566d-95c6-d64c6f46a00a",
          location_fingerprint: finding_location_fingerprint)

        existing_finding = report.findings.find { |f| f.location.fingerprint == created_finding.location_fingerprint }

        create(:vulnerabilities_finding_signature,
               finding: created_finding,
               algorithm_type: existing_finding.signatures.first.algorithm_type,
               signature_sha: existing_finding.signatures.first.signature_sha)

        create(:finding_link,
               finding: created_finding)

        created_finding
      end

      let!(:vulnerability) { create(:vulnerability, findings: [finding], project: project) }

      let(:desired_uuid) do
        Security::VulnerabilityUUID.generate(
          report_type: finding.report_type,
          primary_identifier_fingerprint: finding.primary_identifier.fingerprint,
          location_fingerprint: finding.location_fingerprint,
          project_id: finding.project_id
        )
      end

      let!(:finding_with_uuidv5) do
        create(:vulnerabilities_finding,
               identifiers: [different_identifier],
               primary_identifier: different_identifier,
               scanner: scanner,
               project: project,
               location_fingerprint: '34661e23abcf78ff80dfcc89d0700437612e3f88')
      end

      let(:identifier_of_corrupted_finding) do
        create(:vulnerabilities_identifier,
               project: project,
               fingerprint: '5848739446034d982ef7beece3bb19bff4044ffb')
      end

      let!(:finding_with_wrong_uuidv5) do
        create(:vulnerabilities_finding,
               identifiers: [identifier_of_corrupted_finding],
               primary_identifier: identifier_of_corrupted_finding,
               scanner: scanner,
               project: project,
               uuid: 'd588ff5c-7f65-5ac1-9d11-4f57d65f3faf',
               location_fingerprint: '650bd2dbdad33d2859747c6ae83dcf448ce02394')
      end

      let!(:vulnerability_with_uuid5) { create(:vulnerability, findings: [finding_with_uuidv5], project: project) }

      before do
        project.add_developer(user)
        allow(new_pipeline).to receive(:user).and_return(user)
      end

      subject { described_class.new(new_pipeline, new_report).execute }

      it 'does not change existing UUIDv5' do
        expect { subject }.not_to change(finding_with_uuidv5, :uuid)
      end

      it 'updates UUIDv4 to UUIDv5' do
        # We run `OverrideUuidsService` if the signatures are enabled which
        # kinda disables the logic of this test.
        next if vulnerability_finding_signatures

        finding.uuid = '00000000-1111-2222-3333-444444444444'
        finding.save!

        # this report_finding should be used to update the finding's uuid
        report_finding = new_report.findings.find { |f| f.location.fingerprint == '0e7d0291d912f56880e39d4fbd80d99dd5d327ba' }
        allow(report_finding).to receive(:uuid).and_return(desired_uuid)

        subject

        expect(finding.reload.uuid).to eq(desired_uuid)
      end

      it 'reuses existing scanner' do
        expect { subject }.not_to change { Vulnerabilities::Scanner.count }
      end

      it 'inserts only new identifiers and reuse existing ones' do
        expect { subject }.to change { Vulnerabilities::Identifier.count }.by(4)
      end

      it 'inserts only new links and reuse existing ones' do
        expect { subject }.to change { Vulnerabilities::FindingLink.count }.by(2)
      end

      it 'inserts only new findings and reuse existing ones' do
        expect { subject }.to change { Vulnerabilities::Finding.count }.by(3)
      end

      it 'inserts all finding pipelines (join model) for this new pipeline' do
        expect { subject }.to change { Vulnerabilities::FindingPipeline.where(pipeline: new_pipeline).count }.by(5)
      end

      it 'inserts new vulnerabilities with data from findings from this new pipeline' do
        expect { subject }.to change { Vulnerability.count }.by(4)
      end

      it 'triggers project hooks on new vulnerabilities' do
        expect_next_instances_of(Vulnerability, 4) do |vulnerability|
          expect(vulnerability).to receive(:execute_hooks)
        end

        subject
      end

      it 'updates existing findings with new data' do
        subject

        expect(finding.reload).to have_attributes(severity: 'medium', name: 'Cipher with no integrity')
      end

      it 'updates signatures to match new values' do
        next unless vulnerability_finding_signatures

        expect(finding.signatures.count).to eq(1)
        expect(finding.signatures.first.algorithm_type).to eq('hash')

        existing_signature = finding.signatures.first

        subject

        finding.reload
        existing_signature.reload

        expect(finding.signatures.count).to eq(2)
        signature_algs = finding.signatures.sort_by(&:priority).map(&:algorithm_type)
        expect(signature_algs).to eq(%w[hash scope_offset])

        # check that the existing hash signature was updated/reused
        expect(existing_signature.id).to eq(finding.signatures.find(&:algorithm_hash?).id)
      end

      it 'updates existing vulnerability with new data' do
        subject

        expect(vulnerability.reload).to have_attributes(severity: 'medium', title: 'Cipher with no integrity', title_html: 'Cipher with no integrity')
      end

      context 'when the existing vulnerability is resolved with the latest report' do
        let!(:existing_vulnerability) { create(:vulnerability, report_type: report_type, project: project) }

        it 'marks the vulnerability as resolved on default branch' do
          expect { subject }.to change { existing_vulnerability.reload.resolved_on_default_branch }.from(false).to(true)
        end
      end

      context 'when the existing vulnerability requires manual resolution' do
        let(:trait) { :secret_detection }
        let!(:finding) { create(:vulnerabilities_finding, :with_secret_detection, project: project) }

        it 'wont mark the vulnerability as resolved on default branch' do
          expect { subject }.not_to change { finding.vulnerability.reload.resolved_on_default_branch }
        end
      end

      context 'when the existing resolved vulnerability is discovered again on the latest report' do
        before do
          vulnerability.update_column(:resolved_on_default_branch, true)
        end

        it 'marks the vulnerability as not resolved on default branch' do
          expect { subject }.to change { vulnerability.reload.resolved_on_default_branch }.from(true).to(false)
        end
      end

      context 'when the finding is not valid' do
        before do
          allow(Gitlab::AppLogger).to receive(:warn)
          allow_next_instance_of(::Gitlab::Ci::Reports::Security::Finding) do |finding|
            allow(finding).to receive(:valid?).and_return(false)
          end
        end

        it 'does not create a new finding' do
          expect { subject }.not_to change { Vulnerabilities::Finding.count }
        end

        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end

        it 'puts a warning log' do
          subject

          expect(Gitlab::AppLogger).to have_received(:warn).exactly(new_report.findings.length).times
        end
      end

      context 'vulnerability issue link' do
        context 'when there is no assoiciated issue feedback with finding' do
          it 'does not insert issue links from the new pipeline' do
            expect { subject }.to change { Vulnerabilities::IssueLink.count }.by(0)
          end
        end

        context 'when there is an associated issue feedback with finding' do
          let(:issue) { create(:issue, project: project) }
          let!(:issue_feedback) do
            create(
              :vulnerability_feedback,
              :sast,
              :issue,
              issue: issue,
              project: project,
              project_fingerprint: new_report.findings.first.project_fingerprint
            )
          end

          it 'inserts issue links from the new pipeline' do
            expect { subject }.to change { Vulnerabilities::IssueLink.count }.by(1)
          end

          it 'the issue link is valid' do
            first_finding_uuid = new_report.findings.first.uuid

            subject

            finding = Vulnerabilities::Finding.find_by(uuid: first_finding_uuid)
            vulnerability_id = finding.vulnerability_id
            issue_id = issue.id
            issue_link = Vulnerabilities::IssueLink.find_by(
              vulnerability_id: vulnerability_id,
              issue_id: issue_id
            )

            expect(issue_link).not_to be_nil
          end
        end

        context 'when there is an issue link created for an issue for a vulnerabiltiy' do
          let(:issue) { create(:issue, project: project) }
          let!(:issue_feedback) do
            create(
              :vulnerability_feedback,
              :sast,
              :issue,
              issue: issue,
              project: project,
              project_fingerprint: new_report.findings.find { |f| f.location.fingerprint == finding.location_fingerprint }.project_fingerprint
            )
          end

          let!(:issue_link) { create(:vulnerabilities_issue_link, issue: issue, vulnerability_id: vulnerability.id) }

          it 'will not raise an error' do
            expect { subject }.not_to raise_error
          end

          it 'does not insert issue link from the new pipeline' do
            expect { subject }.to change { Vulnerabilities::IssueLink.count }.by(0)
          end
        end
      end
    end

    context 'with existing data from same pipeline' do
      let(:finding) { create(:vulnerabilities_finding, :with_pipeline, project: project) }
      let!(:finding_pipeline) { create(:vulnerabilities_finding_pipeline, finding: finding, pipeline: pipeline) }
      let(:trait) { :sast }

      it 'skips report' do
        expect(subject).to eq({
          status: :error,
          message: "sast report already stored for this pipeline, skipping..."
        })
      end
    end

    context 'start auto_fix' do
      before do
        stub_licensed_features(vulnerability_auto_fix: true)
      end

      context 'with auto fix supported report type' do
        let(:trait) { :dependency_scanning }

        context 'when auto fix enabled' do
          it 'start auto fix worker' do
            expect(Security::AutoFixWorker).to receive(:perform_async).with(pipeline.id)

            subject
          end
        end

        context 'when auto fix disabled' do
          context 'when feature flag is disabled' do
            before do
              stub_feature_flags(security_auto_fix: false)
            end

            it 'does not start auto fix worker' do
              expect(Security::AutoFixWorker).not_to receive(:perform_async)

              subject
            end
          end

          context 'when auto fix feature is disabled' do
            before do
              project.security_setting.update_column(:auto_fix_dependency_scanning, false)
            end

            it 'does not start auto fix worker' do
              expect(Security::AutoFixWorker).not_to receive(:perform_async)

              subject
            end
          end

          context 'when licensed feature is unavailable' do
            before do
              stub_licensed_features(vulnerability_auto_fix: false)
            end

            it 'does not start auto fix worker' do
              expect(Security::AutoFixWorker).not_to receive(:perform_async)

              subject
            end
          end

          context 'when security setting is not created' do
            before do
              project.security_setting.destroy!
              project.reload
            end

            it 'does not start auto fix worker' do
              expect(Security::AutoFixWorker).not_to receive(:perform_async)
              expect(subject[:status]).to eq(:success)
            end
          end
        end
      end

      context 'with auto fix not supported report type' do
        let(:trait) { :sast }

        before do
          stub_licensed_features(vulnerability_auto_fix: true)
        end

        it 'does not start auto fix worker' do
          expect(Security::AutoFixWorker).not_to receive(:perform_async)

          subject
        end
      end
    end
  end

  context 'vulnerability tracking' do
    let!(:artifact) { create(:ee_ci_job_artifact, :sast_minimal) }

    def generate_new_pipeline
      pipeline = create(:ci_pipeline, :success, project: project)
      build = create(:ci_build, :success, pipeline: pipeline, project: project)
      artifact = create(:ee_ci_job_artifact, :sast_minimal, job: build, project: project)

      [
        pipeline,
        pipeline.security_reports.get_report('sast', artifact)
      ]
    end

    before do
      project.add_developer(user)
      allow(pipeline).to receive(:user).and_return(user)
    end

    # This spec runs three pipelines, ensuring findings are tracked as expected:
    #  1. pipeline creates initial findings without tracking signatures
    #  2. pipeline updates previous findings with tracking signatures
    #  3. pipeline updates previous findings using tracking signatures
    it 'remaps findings across pipeline executions', :aggregate_failures do
      stub_licensed_features(
        sast: true,
        security_dashboard: true,
        vulnerability_finding_signatures: false
      )

      expect do
        expect do
          described_class.new(pipeline, report).execute
        end.not_to(raise_error)
      end.to change { Vulnerabilities::FindingPipeline.count }.by(1)
        .and change { Vulnerability.count }.by(1)
        .and change { Vulnerabilities::Finding.count }.by(1)
        .and change { Vulnerabilities::FindingSignature.count }.by(0)

      stub_licensed_features(
        sast: true,
        security_dashboard: true,
        vulnerability_finding_signatures: true
      )

      pipeline, report = generate_new_pipeline

      allow(pipeline).to receive(:user).and_return(user)

      expect do
        expect do
          described_class.new(pipeline, report).execute
        end.not_to(raise_error)
      end.to change { Vulnerabilities::FindingPipeline.count }.by(1)
        .and change { Vulnerability.count }.by(0)
        .and change { Vulnerabilities::Finding.count }.by(0)
        .and change { Vulnerabilities::FindingSignature.count }.by(2)

      pipeline, report = generate_new_pipeline

      # Update the location of the finding to trigger persistence of signatures
      finding = report.findings.first
      location_data = finding.location.as_json.symbolize_keys.tap { |h| h.delete(:fingerprint) }
      location_data[:start_line] += 1
      location_data[:end_line] += 1

      allow(finding).to receive(:location).and_return(
        Gitlab::Ci::Reports::Security::Locations::Sast.new(**location_data)
      )
      allow(finding).to receive(:raw_metadata).and_return(
        Gitlab::Json.parse(finding.raw_metadata).merge("location" => location_data).to_json
      )
      allow(pipeline).to receive(:user).and_return(user)

      expect do
        expect do
          described_class.new(pipeline, report).execute
        end.not_to(raise_error)
      end.to change { Vulnerabilities::FindingPipeline.count }.by(1)
        .and change { Vulnerability.count }.by(0)
        .and change { Vulnerabilities::Finding.count }.by(0)
        .and change { Vulnerabilities::FindingSignature.count }.by(0)
        .and change { Vulnerabilities::Finding.last.location['start_line'] }.from(29).to(30)
        .and change { Vulnerabilities::Finding.last.location['end_line'] }.from(29).to(30)
    end
  end

  context 'for container scanning' do
    let(:trait) { :container_scanning }

    before do
      stub_licensed_features(container_scanning: true, security_dashboard: true)

      allow(pipeline).to receive(:user).and_return(project.owner)
    end

    it 'populates finding location' do
      subject

      last_finding = Vulnerabilities::Finding.last
      expect(last_finding.read_attribute(:location)).to eq(last_finding.location)
    end
  end
end
