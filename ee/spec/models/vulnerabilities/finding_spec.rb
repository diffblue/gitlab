# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding do
  it { is_expected.to define_enum_for(:confidence) }
  it { is_expected.to define_enum_for(:report_type) }
  it { is_expected.to define_enum_for(:severity) }
  it { is_expected.to define_enum_for(:detection_method) }

  where(vulnerability_finding_signatures_enabled: [true, false])
  with_them do
    before do
      stub_feature_flags(vulnerability_finding_tracking_signatures: vulnerability_finding_signatures_enabled)
      stub_licensed_features(vulnerability_finding_signatures: vulnerability_finding_signatures_enabled)
    end

    describe 'associations' do
      it { is_expected.to belong_to(:project) }
      it { is_expected.to belong_to(:primary_identifier).class_name('Vulnerabilities::Identifier') }
      it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
      it { is_expected.to belong_to(:vulnerability).inverse_of(:findings) }
      it { is_expected.to have_many(:pipelines).class_name('Ci::Pipeline') }
      it { is_expected.to have_many(:finding_pipelines).class_name('Vulnerabilities::FindingPipeline').with_foreign_key('occurrence_id') }
      it { is_expected.to have_many(:identifiers).class_name('Vulnerabilities::Identifier') }
      it { is_expected.to have_many(:finding_identifiers).class_name('Vulnerabilities::FindingIdentifier').with_foreign_key('occurrence_id') }
      it { is_expected.to have_many(:finding_links).class_name('Vulnerabilities::FindingLink').with_foreign_key('vulnerability_occurrence_id') }
      it { is_expected.to have_many(:finding_remediations).class_name('Vulnerabilities::FindingRemediation').with_foreign_key('vulnerability_occurrence_id') }
      it { is_expected.to have_many(:vulnerability_flags).class_name('Vulnerabilities::Flag').with_foreign_key('vulnerability_occurrence_id') }
      it { is_expected.to have_many(:remediations).through(:finding_remediations) }
      it { is_expected.to have_one(:evidence).class_name('Vulnerabilities::Finding::Evidence').with_foreign_key('vulnerability_occurrence_id') }
    end

    describe 'validations' do
      let(:finding) { build(:vulnerabilities_finding) }

      it { is_expected.to validate_presence_of(:scanner) }
      it { is_expected.to validate_presence_of(:project) }
      it { is_expected.to validate_presence_of(:uuid) }
      it { is_expected.to validate_presence_of(:project_fingerprint) }
      it { is_expected.to validate_presence_of(:primary_identifier) }
      it { is_expected.to validate_presence_of(:location_fingerprint) }
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:report_type) }
      it { is_expected.to validate_presence_of(:metadata_version) }
      it { is_expected.to validate_presence_of(:raw_metadata) }
      it { is_expected.to validate_presence_of(:severity) }
      it { is_expected.to validate_presence_of(:confidence) }
      it { is_expected.to validate_presence_of(:detection_method) }

      it { is_expected.to validate_length_of(:description).is_at_most(15000) }
      it { is_expected.to validate_length_of(:message).is_at_most(3000) }
      it { is_expected.to validate_length_of(:solution).is_at_most(7000) }
      it { is_expected.to validate_length_of(:cve).is_at_most(48400) }

      context 'when value for details field is valid' do
        it 'is valid' do
          finding.details = {}

          expect(finding).to be_valid
        end
      end

      context 'when value for details field is invalid' do
        it 'returns errors' do
          finding.details = { invalid: 'data' }

          expect(finding).to be_invalid
          expect(finding.errors.full_messages).to eq(["Details must be a valid json schema"])
        end
      end
    end

    context 'database uniqueness' do
      let(:finding) { create(:vulnerabilities_finding) }
      let(:new_finding) { finding.dup.tap { |o| o.cve = SecureRandom.uuid } }

      it "when all index attributes are identical" do
        expect { new_finding.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end

      describe 'when some parameters are changed' do
        using RSpec::Parameterized::TableSyntax

        # we use block to delay object creations
        where(:key, :factory_name) do
          :primary_identifier | :vulnerabilities_identifier
          :scanner | :vulnerabilities_scanner
          :project | :project
        end

        with_them do
          it "is valid" do
            expect { new_finding.update!({ key => create(factory_name), 'uuid' => SecureRandom.uuid }) }.not_to raise_error
          end
        end
      end
    end

    context 'order' do
      let!(:finding1) { create(:vulnerabilities_finding, confidence: ::Enums::Vulnerability.confidence_levels[:high], severity: ::Enums::Vulnerability.severity_levels[:high]) }
      let!(:finding2) { create(:vulnerabilities_finding, confidence: ::Enums::Vulnerability.confidence_levels[:medium], severity: ::Enums::Vulnerability.severity_levels[:critical]) }
      let!(:finding3) { create(:vulnerabilities_finding, confidence: ::Enums::Vulnerability.confidence_levels[:high], severity: ::Enums::Vulnerability.severity_levels[:critical]) }

      it 'orders by severity and confidence' do
        expect(described_class.all.ordered).to eq([finding3, finding2, finding1])
      end
    end

    describe '.report_type' do
      let(:report_type) { :sast }

      subject { described_class.report_type(report_type) }

      context 'when finding has the corresponding report type' do
        let!(:finding) { create(:vulnerabilities_finding, report_type: report_type) }

        it 'selects the finding' do
          is_expected.to eq([finding])
        end
      end

      context 'when finding does not have security reports' do
        let!(:finding) { create(:vulnerabilities_finding, report_type: :dependency_scanning) }

        it 'does not select the finding' do
          is_expected.to be_empty
        end
      end
    end

    describe '.for_pipelines_with_sha' do
      let(:project) { create(:project) }
      let(:pipeline) { create(:ci_pipeline, :success, project: project) }

      before do
        create(:vulnerabilities_finding, pipelines: [pipeline], project: project)
      end

      subject(:findings) { described_class.for_pipelines_with_sha([pipeline]) }

      it 'sets the sha' do
        expect(findings.first.sha).to eq(pipeline.sha)
      end
    end

    describe '.by_report_types' do
      let!(:vulnerability_sast) { create(:vulnerabilities_finding, report_type: :sast) }
      let!(:vulnerability_secret_detection) { create(:vulnerabilities_finding, report_type: :secret_detection) }
      let!(:vulnerability_dast) { create(:vulnerabilities_finding, report_type: :dast) }
      let!(:vulnerability_depscan) { create(:vulnerabilities_finding, report_type: :dependency_scanning) }
      let!(:vulnerability_covfuzz) { create(:vulnerabilities_finding, report_type: :coverage_fuzzing) }
      let!(:vulnerability_apifuzz) { create(:vulnerabilities_finding, report_type: :api_fuzzing) }

      subject { described_class.by_report_types(param) }

      context 'with one param' do
        let(:param) { Vulnerabilities::Finding.report_types['sast'] }

        it 'returns found record' do
          is_expected.to contain_exactly(vulnerability_sast)
        end
      end

      context 'with array of params' do
        let(:param) do
          [
            Vulnerabilities::Finding.report_types['dependency_scanning'],
            Vulnerabilities::Finding.report_types['dast'],
            Vulnerabilities::Finding.report_types['secret_detection'],
            Vulnerabilities::Finding.report_types['coverage_fuzzing'],
            Vulnerabilities::Finding.report_types['api_fuzzing']
          ]
        end

        it 'returns found records' do
          is_expected.to contain_exactly(
            vulnerability_dast,
            vulnerability_depscan,
            vulnerability_secret_detection,
            vulnerability_covfuzz,
            vulnerability_apifuzz)
        end
      end

      context 'without found record' do
        let(:param) { ::Enums::Vulnerability.report_types['container_scanning']}

        it 'returns empty collection' do
          is_expected.to be_empty
        end
      end
    end

    describe '.by_projects' do
      let!(:vulnerability1) { create(:vulnerabilities_finding) }
      let!(:vulnerability2) { create(:vulnerabilities_finding) }

      subject { described_class.by_projects(param) }

      context 'with found record' do
        let(:param) { vulnerability1.project_id }

        it 'returns found record' do
          is_expected.to contain_exactly(vulnerability1)
        end
      end
    end

    describe '.by_scanners' do
      context 'with found record' do
        it 'returns found record' do
          vulnerability1 = create(:vulnerabilities_finding)
          create(:vulnerabilities_finding)
          param = vulnerability1.scanner_id

          result = described_class.by_scanners(param)

          expect(result).to contain_exactly(vulnerability1)
        end
      end
    end

    describe '.by_severities' do
      let!(:vulnerability_high) { create(:vulnerabilities_finding, severity: :high) }
      let!(:vulnerability_low) { create(:vulnerabilities_finding, severity: :low) }

      subject { described_class.by_severities(param) }

      context 'with one param' do
        let(:param) { described_class.severities[:low] }

        it 'returns found record' do
          is_expected.to contain_exactly(vulnerability_low)
        end
      end

      context 'without found record' do
        let(:param) { described_class.severities[:unknown] }

        it 'returns empty collection' do
          is_expected.to be_empty
        end
      end
    end

    describe '.by_confidences' do
      let!(:vulnerability_high) { create(:vulnerabilities_finding, confidence: :high) }
      let!(:vulnerability_low) { create(:vulnerabilities_finding, confidence: :low) }

      subject { described_class.by_confidences(param) }

      context 'with matching param' do
        let(:param) { described_class.confidences[:low] }

        it 'returns found record' do
          is_expected.to contain_exactly(vulnerability_low)
        end
      end

      context 'with non-matching param' do
        let(:param) { described_class.confidences[:unknown] }

        it 'returns empty collection' do
          is_expected.to be_empty
        end
      end
    end

    describe '.counted_by_severity' do
      let!(:high_vulnerabilities) { create_list(:vulnerabilities_finding, 3, severity: :high) }
      let!(:medium_vulnerabilities) { create_list(:vulnerabilities_finding, 2, severity: :medium) }
      let!(:low_vulnerabilities) { create_list(:vulnerabilities_finding, 1, severity: :low) }

      subject { described_class.counted_by_severity }

      it 'returns counts' do
        is_expected.to eq({ 4 => 1, 5 => 2, 6 => 3 })
      end
    end

    describe '.undismissed' do
      let_it_be(:project) { create(:project) }
      let_it_be(:project2) { create(:project) }

      let!(:finding1) { create(:vulnerabilities_finding, project: project) }
      let!(:finding2) { create(:vulnerabilities_finding, project: project, report_type: :dast) }
      let!(:finding3) { create(:vulnerabilities_finding, project: project2) }

      before do
        create(
          :vulnerability_feedback,
          :dismissal,
          project: finding1.project,
          project_fingerprint: finding1.project_fingerprint
        )
        create(
          :vulnerability_feedback,
          :dismissal,
          project_fingerprint: finding2.project_fingerprint,
          project: project2
        )
        create(
          :vulnerability_feedback,
          :dismissal,
          category: :sast,
          project_fingerprint: finding2.project_fingerprint,
          project: finding2.project
        )
      end

      it 'returns all non-dismissed findings' do
        expect(described_class.undismissed).to contain_exactly(finding2, finding3)
      end

      it 'returns non-dismissed findings for project' do
        expect(project2.vulnerability_findings.undismissed).to contain_exactly(finding3)
      end
    end

    describe '.dismissed' do
      let_it_be(:project) { create(:project) }
      let_it_be(:project2) { create(:project) }

      let!(:finding1) { create(:vulnerabilities_finding, project: project) }
      let!(:finding2) { create(:vulnerabilities_finding, project: project, report_type: :dast) }
      let!(:finding3) { create(:vulnerabilities_finding, project: project2) }

      before do
        create(
          :vulnerability_feedback,
          :dismissal,
          project: finding1.project,
          project_fingerprint: finding1.project_fingerprint
        )
        create(
          :vulnerability_feedback,
          :dismissal,
          project_fingerprint: finding2.project_fingerprint,
          project: project2
        )
        create(
          :vulnerability_feedback,
          :dismissal,
          category: :sast,
          project_fingerprint: finding2.project_fingerprint,
          project: finding2.project
        )
      end

      it 'returns all dismissed findings' do
        expect(described_class.dismissed).to contain_exactly(finding1)
      end

      it 'returns dismissed findings for project' do
        expect(project.vulnerability_findings.dismissed).to contain_exactly(finding1)
      end
    end

    describe '.batch_count_by_project_and_severity' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project) }
      let(:project) { create(:project) }

      it 'fetches a vulnerability count for the given project and severity' do
        create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)

        count = described_class.batch_count_by_project_and_severity(project.id, 'high')

        expect(count).to be(1)
      end

      it 'only returns vulnerabilities from the latest successful pipeline' do
        old_pipeline = create(:ci_pipeline, :success, project: project)
        latest_pipeline = create(:ci_pipeline, :success, project: project)
        latest_failed_pipeline = create(:ci_pipeline, :failed, project: project)
        create(:vulnerabilities_finding, pipelines: [old_pipeline], project: project, severity: :critical)
        create(
          :vulnerabilities_finding,
          pipelines: [latest_failed_pipeline],
          project: project,
          severity: :critical
        )
        create_list(
          :vulnerabilities_finding, 2,
          pipelines: [latest_pipeline],
          project: project,
          severity: :critical
        )

        count = described_class.batch_count_by_project_and_severity(project.id, 'critical')

        expect(count).to be(2)
      end

      it 'returns 0 when there are no vulnerabilities for that severity level' do
        count = described_class.batch_count_by_project_and_severity(project.id, 'high')

        expect(count).to be(0)
      end

      it 'batch loads the counts' do
        projects = create_list(:project, 2)

        projects.each do |project|
          pipeline = create(:ci_pipeline, :success, project: project)

          create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)
          create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :low)
        end

        projects_and_severities = [
          [projects.first, 'high'],
          [projects.first, 'low'],
          [projects.second, 'high'],
          [projects.second, 'low']
        ]

        counts = projects_and_severities.map do |(project, severity)|
          described_class.batch_count_by_project_and_severity(project.id, severity)
        end

        expect { expect(counts).to all(be 1) }.not_to exceed_query_limit(1)
      end

      it 'does not include dismissed vulnerabilities in the counts' do
        create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)
        dismissed_vulnerability = create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)
        create(
          :vulnerability_feedback,
          project: project,
          project_fingerprint: dismissed_vulnerability.project_fingerprint,
          feedback_type: :dismissal
        )

        count = described_class.batch_count_by_project_and_severity(project.id, 'high')

        expect(count).to be(1)
      end

      it "does not overwrite one project's counts with another's" do
        project1 = create(:project)
        project2 = create(:project)
        pipeline1 = create(:ci_pipeline, :success, project: project1)
        pipeline2 = create(:ci_pipeline, :success, project: project2)
        create(:vulnerabilities_finding, pipelines: [pipeline1], project: project1, severity: :critical)
        create(:vulnerabilities_finding, pipelines: [pipeline2], project: project2, severity: :high)

        project1_critical_count = described_class.batch_count_by_project_and_severity(project1.id, 'critical')
        project1_high_count = described_class.batch_count_by_project_and_severity(project1.id, 'high')
        project2_critical_count = described_class.batch_count_by_project_and_severity(project2.id, 'critical')
        project2_high_count = described_class.batch_count_by_project_and_severity(project2.id, 'high')

        expect(project1_critical_count).to be(1)
        expect(project1_high_count).to be(0)
        expect(project2_critical_count).to be(0)
        expect(project2_high_count).to be(1)
      end
    end

    describe '#false_positive?' do
      let_it_be(:finding) { create(:vulnerabilities_finding) }
      let_it_be(:finding_with_fp) { create(:vulnerabilities_finding, vulnerability_flags: [create(:vulnerabilities_flag)]) }

      it 'returns false if the finding does not have any false_positive' do
        expect(finding.false_positive?).to eq(false)
      end

      it 'returns true if the finding has false_positives' do
        expect(finding_with_fp.false_positive?).to eq(true)
      end
    end

    describe '#links' do
      let_it_be(:finding, reload: true) do
        create(
          :vulnerabilities_finding,
          raw_metadata: {
            links: [{ url: 'https://raw.gitlab.com', name: 'raw_metadata_link' }]
          }.to_json
        )
      end

      subject(:links) { finding.links }

      context 'when there are no finding links' do
        it 'returns links from raw_metadata' do
          expect(links).to eq([{ 'url' => 'https://raw.gitlab.com', 'name' => 'raw_metadata_link' }])
        end
      end

      context 'when there are finding links assigned to given finding' do
        let_it_be(:finding_link) { create(:finding_link, name: 'finding_link', url: 'https://link.gitlab.com', finding: finding) }

        it 'returns links from finding link' do
          expect(links).to eq([{ 'url' => 'https://link.gitlab.com', 'name' => 'finding_link' }])
        end
      end
    end

    describe '#remediations' do
      let_it_be(:project) { create_default(:project) }
      let_it_be(:finding, refind: true) { create(:vulnerabilities_finding) }

      subject { finding.remediations }

      context 'when the finding has associated remediation records' do
        let_it_be(:persisted_remediation) { create(:vulnerabilities_remediation, findings: [finding]) }
        let_it_be(:remediation_hash) { { 'summary' => persisted_remediation.summary, 'diff' => persisted_remediation.diff } }

        it { is_expected.to eq([remediation_hash]) }
      end

      context 'when the finding does not have associated remediation records' do
        context 'when the finding has remediations in `raw_metadata`' do
          let(:raw_remediation) { { summary: 'foo', diff: 'bar' }.stringify_keys }

          before do
            raw_metadata = { remediations: [raw_remediation] }.to_json
            finding.update!(raw_metadata: raw_metadata)
          end

          it { is_expected.to eq([raw_remediation]) }
        end

        context 'when the finding does not have remediations in `raw_metadata`' do
          before do
            finding.update!(raw_metadata: {}.to_json)
          end

          it { is_expected.to be_nil }
        end
      end
    end

    describe 'feedback' do
      let_it_be(:project) { create(:project) }

      let_it_be(:finding) do
        create(
          :vulnerabilities_finding,
          report_type: :dependency_scanning,
          project: project
        )
      end

      describe '#issue_feedback' do
        let_it_be(:issue) { create(:issue, project: project) }
        let_it_be(:issue_feedback) do
          create(
            :vulnerability_feedback,
            :dependency_scanning,
            :issue,
            issue: issue,
            project: project,
            project_fingerprint: finding.project_fingerprint
          )
        end

        let(:vulnerability) { create(:vulnerability, findings: [finding]) }

        context 'when there is issue link present' do
          let!(:issue_link) { create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)}

          it 'returns associated feedback' do
            expect(finding.issue_feedback).to eq(issue_feedback)
          end

          context 'when there is no feedback for the vulnerability' do
            let(:vulnerability_no_feedback) { create(:vulnerability, findings: [finding_no_feedback]) }
            let!(:finding_no_feedback) { create(:vulnerabilities_finding, :dependency_scanning, project: project) }

            it 'does not return unassociated feedback' do
              expect(finding_no_feedback.issue_feedback).to be_nil
            end
          end

          context 'when there is no vulnerability associated with the finding' do
            let!(:finding_no_vulnerability) { create(:vulnerabilities_finding, :dependency_scanning, project: project) }

            it 'does not return feedback' do
              expect(finding_no_vulnerability.issue_feedback).to be_nil
            end
          end
        end

        context 'when there is no issue link present' do
          it 'returns associated feedback' do
            expect(finding.issue_feedback).to eq(issue_feedback)
          end
        end
      end

      describe '#dismissal_feedback' do
        let!(:dismissal_feedback) do
          create(
            :vulnerability_feedback,
            :dependency_scanning,
            :dismissal,
            project: project,
            project_fingerprint: finding.project_fingerprint
          )
        end

        it 'returns associated feedback' do
          feedback = finding.dismissal_feedback

          expect(feedback).to be_present
          expect(feedback[:project_id]).to eq project.id
          expect(feedback[:feedback_type]).to eq 'dismissal'
        end
      end

      describe '#merge_request_feedback' do
        let(:merge_request) { create(:merge_request, source_project: project) }
        let!(:merge_request_feedback) do
          create(
            :vulnerability_feedback,
            :dependency_scanning,
            :merge_request,
            merge_request: merge_request,
            project: project,
            project_fingerprint: finding.project_fingerprint
          )
        end

        it 'returns associated feedback' do
          feedback = finding.merge_request_feedback

          expect(feedback).to be_present
          expect(feedback[:project_id]).to eq project.id
          expect(feedback[:feedback_type]).to eq 'merge_request'
          expect(feedback[:merge_request_id]).to eq merge_request.id
        end
      end
    end

    describe '#load_feedback' do
      let_it_be(:project) { create(:project) }
      let_it_be(:finding) do
        create(
          :vulnerabilities_finding,
          report_type: :dependency_scanning,
          project: project
        )
      end

      let_it_be(:feedback) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :dismissal,
          project: project,
          project_fingerprint: finding.project_fingerprint
        )
      end

      let(:expected_feedback) { [feedback] }

      subject(:load_feedback) { finding.load_feedback.to_a }

      it { is_expected.to eq(expected_feedback) }

      context 'when you have multiple findings' do
        let_it_be(:finding_2) do
          create(
            :vulnerabilities_finding,
            report_type: :dependency_scanning,
            project: project
          )
        end

        let_it_be(:feedback_2) do
          create(
            :vulnerability_feedback,
            :dependency_scanning,
            :dismissal,
            project: project,
            project_fingerprint: finding_2.project_fingerprint
          )
        end

        let(:expected_feedback) { [[feedback], [feedback_2]] }

        subject(:load_feedback) { [finding, finding_2].map(&:load_feedback) }

        it { is_expected.to eq(expected_feedback) }
      end
    end

    describe '#state' do
      before do
        create(:vulnerability, :dismissed, project: finding_with_issue.project, findings: [finding_with_issue])
      end

      let(:unresolved_finding) { create(:vulnerabilities_finding) }
      let(:confirmed_finding) { create(:vulnerabilities_finding, :confirmed) }
      let(:resolved_finding) { create(:vulnerabilities_finding, :resolved) }
      let(:dismissed_finding) { create(:vulnerabilities_finding, :dismissed) }
      let(:finding_with_issue) { create(:vulnerabilities_finding, :with_issue_feedback) }

      it 'returns the expected state for a unresolved finding' do
        expect(unresolved_finding.state).to eq 'detected'
      end

      it 'returns the expected state for a confirmed finding' do
        expect(confirmed_finding.state).to eq 'confirmed'
      end

      it 'returns the expected state for a resolved finding' do
        expect(resolved_finding.state).to eq 'resolved'
      end

      it 'returns the expected state for a dismissed finding' do
        expect(dismissed_finding.state).to eq 'dismissed'
      end

      context 'when a vulnerability present for a dismissed finding' do
        before do
          create(:vulnerability, project: dismissed_finding.project, findings: [dismissed_finding])
        end

        it 'still reports a dismissed state' do
          expect(dismissed_finding.state).to eq 'dismissed'
        end
      end

      context 'when a non-dismissal feedback present for a finding belonging to a closed vulnerability' do
        before do
          create(:vulnerability_feedback, :issue, project: resolved_finding.project)
        end

        it 'reports as resolved' do
          expect(resolved_finding.state).to eq 'resolved'
        end
      end
    end

    describe '#scanner_name' do
      let(:vulnerabilities_finding) { create(:vulnerabilities_finding) }

      subject(:scanner_name) { vulnerabilities_finding.scanner_name }

      it { is_expected.to eq(vulnerabilities_finding.scanner.name) }
    end

    describe '#description' do
      let(:finding) { build(:vulnerabilities_finding) }
      let(:expected_description) { finding.metadata['description'] }

      subject { finding.description }

      context 'when description metadata key is present' do
        it { is_expected.to eql(expected_description) }
      end

      context 'when description data is present' do
        let(:finding) { build(:vulnerabilities_finding, description: 'Vulnerability description') }

        it { is_expected.to eq('Vulnerability description') }
      end
    end

    describe '#solution' do
      subject { vulnerabilities_finding.solution }

      context 'when solution metadata key is present' do
        let(:vulnerabilities_finding) { build(:vulnerabilities_finding) }

        it { is_expected.to eq(vulnerabilities_finding.metadata['solution']) }
      end

      context 'when remediations key is present in finding' do
        let(:vulnerabilities_finding) do
          build(:vulnerabilities_finding_with_remediation, summary: "Test remediation")
        end

        it { is_expected.to eq(vulnerabilities_finding.remediations.dig(0, 'summary')) }
      end

      context 'when solution data is present' do
        let(:vulnerabilities_finding) { build(:vulnerabilities_finding, solution: 'Vulnerability solution') }

        it { is_expected.to eq('Vulnerability solution') }
      end
    end

    describe '#location' do
      let(:finding) { build(:vulnerabilities_finding) }
      let(:expected_location) { finding.metadata['location'] }

      subject { finding.location }

      context 'when location metadata key is present' do
        it { is_expected.to eql(expected_location) }
      end

      context 'when location data is present' do
        let(:location) { { 'class' => 'class', 'end_line' => 3, 'file' => 'test_file.rb', 'start_line' => 1 } }
        let(:finding) { build(:vulnerabilities_finding, location: location) }

        it { is_expected.to eq(location) }
      end
    end

    describe '#evidence' do
      subject { finding.evidence }

      context 'has an evidence fields' do
        let(:finding) { create(:vulnerabilities_finding) }
        let(:evidence) { finding.metadata['evidence'] }

        it do
          is_expected.to match a_hash_including(
            summary: evidence['summary'],
            request: {
              headers: [
                {
                  name: evidence['request']['headers'][0]['name'],
                  value: evidence['request']['headers'][0]['value']
                }
              ],
              url: evidence['request']['url'],
              method: evidence['request']['method'],
              body: evidence['request']['body']
            },
            response: {
              headers: [
                {
                  name: evidence['response']['headers'][0]['name'],
                  value: evidence['response']['headers'][0]['value']
                }
              ],
              reason_phrase: evidence['response']['reason_phrase'],
              status_code: evidence['response']['status_code'],
              body: evidence['request']['body']
            },
            source: {
              id: evidence.dig('source', 'id'),
              name: evidence.dig('source', 'name'),
              url: evidence.dig('source', 'url')
            },
            supporting_messages: [
              {
                name: evidence.dig('supporting_messages')[0].dig('name'),
                request: {
                  headers: [
                    {
                      name: evidence.dig('supporting_messages')[0].dig('request', 'headers')[0].dig('name'),
                      value: evidence.dig('supporting_messages')[0].dig('request', 'headers')[0].dig('value')
                    }
                  ],
                  url: evidence.dig('supporting_messages')[0].dig('request', 'url'),
                  method: evidence.dig('supporting_messages')[0].dig('request', 'method'),
                  body: evidence.dig('supporting_messages')[0].dig('request', 'body')
                },
                response: evidence.dig('supporting_messages')[0].dig('response')
              },
              {
                name: evidence.dig('supporting_messages')[1].dig('name'),
                request: {
                  headers: [
                    {
                      name: evidence.dig('supporting_messages')[1].dig('request', 'headers')[0].dig('name'),
                      value: evidence.dig('supporting_messages')[1].dig('request', 'headers')[0].dig('value')
                    }
                  ],
                  url: evidence.dig('supporting_messages')[1].dig('request', 'url'),
                  method: evidence.dig('supporting_messages')[1].dig('request', 'method'),
                  body: evidence.dig('supporting_messages')[1].dig('request', 'body')
                },
                response: {
                  headers: [
                    {
                      name: evidence.dig('supporting_messages')[1].dig('response', 'headers')[0].dig('name'),
                      value: evidence.dig('supporting_messages')[1].dig('response', 'headers')[0].dig('value')
                    }
                  ],
                  reason_phrase: evidence.dig('supporting_messages')[1].dig('response', 'reason_phrase'),
                  status_code: evidence.dig('supporting_messages')[1].dig('response', 'status_code'),
                  body: evidence.dig('supporting_messages')[1].dig('response', 'body')
                }
              }
            ]
          )
        end
      end

      context 'has no evidence summary when evidence is present, summary is not' do
        let(:finding) { create(:vulnerabilities_finding, raw_metadata: { evidence: {} }) }

        it do
          is_expected.to match a_hash_including(
            summary: nil,
            source: nil,
            supporting_messages: [],
            request: nil,
            response: nil)
        end
      end
    end

    describe '#message' do
      let(:finding) { build(:vulnerabilities_finding) }
      let(:expected_message) { finding.metadata['message'] }

      subject { finding.message }

      context 'when message metadata key is present' do
        it { is_expected.to eql(expected_message) }
      end

      context 'when message data is present' do
        let(:finding) { build(:vulnerabilities_finding, message: 'Vulnerability message') }

        it { is_expected.to eq('Vulnerability message') }
      end
    end

    describe '#cve_value' do
      let(:finding) { build(:vulnerabilities_finding) }
      let(:expected_cve) { 'CVE-2020-0000' }

      subject { finding.cve_value }

      before do
        finding.identifiers << build(:vulnerabilities_identifier, external_type: 'cve', name: expected_cve)
      end

      context 'when cve metadata key is present' do
        it { is_expected.to eql(expected_cve) }
      end

      context 'when cve data is present' do
        let(:finding) { build(:vulnerabilities_finding, cve: 'Vulnerability cve') }

        it { is_expected.to eq('Vulnerability cve') }
      end
    end

    describe '#cwe_value' do
      let(:finding) { build(:vulnerabilities_finding) }
      let(:expected_cwe) { 'CWE-0000' }

      subject { finding.cwe_value }

      before do
        finding.identifiers << build(:vulnerabilities_identifier, external_type: 'cwe', name: expected_cwe)
      end

      it { is_expected.to eql(expected_cwe) }
    end

    describe '#other_identifier_values' do
      let(:finding) { build(:vulnerabilities_finding) }
      let(:expected_values) { ['ID 1', 'ID 2'] }

      subject { finding.other_identifier_values }

      before do
        finding.identifiers << build(:vulnerabilities_identifier, external_type: 'foo', name: expected_values.first)
        finding.identifiers << build(:vulnerabilities_identifier, external_type: 'bar', name: expected_values.second)
      end

      it { is_expected.to match_array(expected_values) }
    end

    describe "#metadata" do
      let(:finding) { build(:vulnerabilities_finding) }

      subject { finding.metadata }

      it "handles bool JSON data" do
        allow(finding).to receive(:raw_metadata) { "true" }

        expect(subject).to eq({})
      end

      it "handles string JSON data" do
        allow(finding).to receive(:raw_metadata) { '"test"' }

        expect(subject).to eq({})
      end

      it "parses JSON data" do
        allow(finding).to receive(:raw_metadata) { '{ "test": true }' }

        expect(subject).to eq({ "test" => true })
      end
    end

    describe '#uuid_v5' do
      let(:project) { create(:project) }
      let(:report_type) { :sast }
      let(:identifier_fingerprint) { 'fooo' }
      let(:location_fingerprint) { 'zooo' }
      let(:identifier) { build(:vulnerabilities_identifier, fingerprint: identifier_fingerprint) }
      let(:expected_uuid) { 'this-is-supposed-to-a-uuid' }
      let(:finding) do
        build(:vulnerabilities_finding, report_type,
              uuid: uuid,
              project: project,
              primary_identifier: identifier,
              location_fingerprint: location_fingerprint)
      end

      subject(:uuid_v5) { finding.uuid_v5 }

      before do
        allow(::Gitlab::UUID).to receive(:v5).and_return(expected_uuid)
      end

      context 'when the finding has a version 4 uuid' do
        let(:uuid) { SecureRandom.uuid }
        let(:uuid_name_value) { "#{report_type}-#{identifier_fingerprint}-#{location_fingerprint}-#{project.id}" }

        it 'returns the calculated uuid for the finding' do
          expect(uuid_v5).to eq(expected_uuid)
          expect(::Gitlab::UUID).to have_received(:v5).with(uuid_name_value)
        end
      end

      context 'when the finding has a version 5 uuid' do
        let(:uuid) { '6756ebb6-8465-5c33-9af9-c5c8b117aefb' }

        it 'returns the uuid of the finding' do
          expect(uuid_v5).to eq(uuid)
          expect(::Gitlab::UUID).not_to have_received(:v5)
        end
      end
    end

    describe '#eql?' do
      let(:project) { create(:project) }
      let(:report_type) { :sast }
      let(:identifier_fingerprint) { 'fooo' }
      let(:identifier) { build(:vulnerabilities_identifier, fingerprint: identifier_fingerprint) }
      let(:location_fingerprint1) { 'fingerprint1' }
      let(:location_fingerprint2) { 'fingerprint2' }
      let(:finding1) do
        build(:vulnerabilities_finding, report_type,
              project: project,
              primary_identifier: identifier,
              location_fingerprint: location_fingerprint1)
      end

      let(:finding2) do
        build(:vulnerabilities_finding, report_type,
              project: project,
              primary_identifier: identifier,
              location_fingerprint: location_fingerprint2)
      end

      it 'matches the finding based on enabled tracking methods (if feature flag enabled)' do
        signature1 = create(
          :vulnerabilities_finding_signature,
          finding: finding1
        )

        signature2 = create(
          :vulnerabilities_finding_signature,
          finding: finding2,
          signature_sha: signature1.signature_sha
        )

        # verify that the signatures do exist and that they match
        expect(finding1.signatures.size).to eq(1)
        expect(finding2.signatures.size).to eq(1)
        expect(signature1.eql?(signature2)).to be(true)

        # now verify that the correct matching method was used for eql?
        expect(finding1.eql?(finding2)).to be(vulnerability_finding_signatures_enabled)
      end

      it 'wont match other record types' do
        historical_stat = build(:vulnerability_historical_statistic, project: project)
        expect(finding1.eql?(historical_stat)).to be(false)
      end

      context 'short circuits on the highest priority signature match' do
        using RSpec::Parameterized::TableSyntax

        let(:same_hash) { false }
        let(:same_location) { false }
        let(:create_scope_offset) { false }
        let(:same_scope_offset) { false}

        let(:create_signatures) do
          signature1_hash = create(
            :vulnerabilities_finding_signature,
            algorithm_type: 'hash',
            finding: finding1
          )
          sha = same_hash ? signature1_hash.signature_sha : ::Digest::SHA1.digest(SecureRandom.hex(50))
          create(
            :vulnerabilities_finding_signature,
            algorithm_type: 'hash',
            finding: finding2,
            signature_sha: sha
          )

          signature1_location = create(
            :vulnerabilities_finding_signature,
            algorithm_type: 'location',
            finding: finding1
          )
          sha = same_location ? signature1_location.signature_sha : ::Digest::SHA1.digest(SecureRandom.hex(50))
          create(
            :vulnerabilities_finding_signature,
            algorithm_type: 'location',
            finding: finding2,
            signature_sha: sha
          )

          signature1_scope_offset = create(
            :vulnerabilities_finding_signature,
            algorithm_type: 'scope_offset',
            finding: finding1
          )

          if create_scope_offset
            sha = same_scope_offset ? signature1_scope_offset.signature_sha : ::Digest::SHA1.digest(SecureRandom.hex(50))
            create(
              :vulnerabilities_finding_signature,
              algorithm_type: 'scope_offset',
              finding: finding2,
              signature_sha: sha
            )
          end
        end

        where(:same_hash, :same_location, :create_scope_offset, :same_scope_offset, :should_match) do
          true  | true  | true  | true  | true  # everything matches
          false | false | true  | false | false # nothing matches
          true  | true  | true  | false | false # highest priority matches alg/priority but not on value
          false | false | true  | true  | true  # highest priority matches alg/priority and value
          false | true  | false | false | true  # highest priority is location, matches alg/priority and value
        end
        with_them do
          it 'matches correctly' do
            next unless vulnerability_finding_signatures_enabled

            create_signatures
            expect(finding1.eql?(finding2)).to be(should_match)
          end
        end
      end
    end
  end
end
