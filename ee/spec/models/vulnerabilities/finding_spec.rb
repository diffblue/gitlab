# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vulnerabilities::Finding, feature_category: :vulnerability_management do
  it { is_expected.to define_enum_for(:confidence) }
  it { is_expected.to define_enum_for(:report_type) }
  it { is_expected.to define_enum_for(:severity) }
  it { is_expected.to define_enum_for(:detection_method) }

  it { is_expected.to have_locked_schema('59b8d2a07cd44aefeba3a4e03c18a1907be632efc99ada63cf73a5f5e100b8ac').reference('https://gitlab.com/gitlab-org/gitlab/-/issues/349315') }

  where(vulnerability_finding_signatures: [true, false])
  with_them do
    before do
      stub_licensed_features(vulnerability_finding_signatures: vulnerability_finding_signatures)
    end

    describe 'associations' do
      it { is_expected.to belong_to(:project) }
      it { is_expected.to belong_to(:primary_identifier).class_name('Vulnerabilities::Identifier') }
      it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
      it { is_expected.to belong_to(:vulnerability).inverse_of(:findings) }
      it { is_expected.to have_many(:finding_pipelines).class_name('Vulnerabilities::FindingPipeline').with_foreign_key('occurrence_id') }
      it { is_expected.to have_many(:identifiers).class_name('Vulnerabilities::Identifier') }
      it { is_expected.to have_many(:finding_identifiers).class_name('Vulnerabilities::FindingIdentifier').with_foreign_key('occurrence_id') }
      it { is_expected.to have_many(:finding_links).class_name('Vulnerabilities::FindingLink').with_foreign_key('vulnerability_occurrence_id') }
      it { is_expected.to have_many(:finding_remediations).class_name('Vulnerabilities::FindingRemediation').with_foreign_key('vulnerability_occurrence_id') }
      it { is_expected.to have_many(:vulnerability_flags).class_name('Vulnerabilities::Flag').with_foreign_key('vulnerability_occurrence_id') }
      it { is_expected.to have_many(:remediations).through(:finding_remediations) }
      it { is_expected.to have_one(:finding_evidence).class_name('Vulnerabilities::Finding::Evidence').with_foreign_key('vulnerability_occurrence_id') }
      it { is_expected.to have_many(:feedbacks).with_primary_key('uuid').class_name('Vulnerabilities::Feedback').with_foreign_key('finding_uuid') }
      it { is_expected.to have_many(:state_transitions).through(:vulnerability) }
      it { is_expected.to have_many(:issue_links).through(:vulnerability) }
      it { is_expected.to have_many(:merge_request_links).through(:vulnerability) }
      it { is_expected.to have_many(:security_findings).class_name('Security::Finding') }
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
        let(:param) { ::Enums::Vulnerability.report_types['container_scanning'] }

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

    context 'when determining dimissal status of findings' do
      let_it_be(:project) { create(:project) }
      let_it_be(:project2) { create(:project) }

      let!(:finding1) { create(:vulnerabilities_finding, project: project) }
      let!(:finding2) { create(:vulnerabilities_finding, project: project2, report_type: :dast) }
      let!(:finding3) { create(:vulnerabilities_finding, project: project2) }
      let!(:finding4) { create(:vulnerabilities_finding, project: project) }

      before do
        create(
          :vulnerability_feedback,
          :dismissal,
          finding_uuid: finding1.uuid
        )
        create(
          :vulnerability_feedback,
          :dismissal,
          finding_uuid: finding2.uuid
        )
      end

      describe '.undismissed' do
        it 'returns all non-dismissed findings' do
          expect(described_class.undismissed).to contain_exactly(finding3, finding4)
        end

        it 'returns non-dismissed findings for project' do
          expect(project2.vulnerability_findings.undismissed).to contain_exactly(finding3)
        end
      end

      describe '.dismissed' do
        it 'returns all dismissed findings' do
          expect(described_class.dismissed).to contain_exactly(finding1, finding2)
        end

        it 'returns dismissed findings for project' do
          expect(project.vulnerability_findings.dismissed).to contain_exactly(finding1)
        end
      end
    end

    describe '.by_location_image' do
      let_it_be(:vulnerability) { create(:vulnerability, report_type: 'cluster_image_scanning') }
      let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, vulnerability: vulnerability) }
      let_it_be(:image) { finding.location['image'] }

      before do
        finding_with_different_image = create(
          :vulnerabilities_finding,
          :with_cluster_image_scanning_scanning_metadata,
          vulnerability: create(:vulnerability, report_type: 'cluster_image_scanning')
        )
        finding_with_different_image.location['image'] = 'alpine:latest'
        finding_with_different_image.save!

        create(:vulnerabilities_finding, report_type: :dast)
      end

      subject(:cluster_findings) { described_class.by_location_image(image) }

      it 'returns findings with given image' do
        expect(cluster_findings).to contain_exactly(finding)
      end
    end

    describe '.by_location_cluster' do
      let_it_be(:vulnerability) { create(:vulnerability, report_type: 'cluster_image_scanning') }
      let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, vulnerability: vulnerability) }
      let_it_be(:cluster_ids) { [finding.location['kubernetes_resource']['cluster_id']] }

      before do
        finding_with_different_cluster_id = create(
          :vulnerabilities_finding,
          :with_cluster_image_scanning_scanning_metadata,
          vulnerability: create(:vulnerability, report_type: 'cluster_image_scanning')
        )
        finding_with_different_cluster_id.location['kubernetes_resource']['cluster_id'] = '2'
        finding_with_different_cluster_id.save!

        create(:vulnerabilities_finding, report_type: :dast)
      end

      subject(:cluster_findings) { described_class.by_location_cluster(cluster_ids) }

      it 'returns findings with given cluster_id' do
        expect(cluster_findings).to contain_exactly(finding)
      end
    end

    describe '.by_location_cluster_agent' do
      let_it_be(:vulnerability) { create(:vulnerability, report_type: 'cluster_image_scanning') }
      let_it_be(:cluster_agent) { create(:cluster_agent, project: vulnerability.project) }
      let_it_be(:other_cluster_agent) { create(:cluster_agent, project: vulnerability.project) }
      let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, agent_id: cluster_agent.id.to_s, vulnerability: vulnerability) }
      let_it_be(:finding_with_different_agent_id) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, agent_id: other_cluster_agent.id.to_s, vulnerability: vulnerability) }
      let_it_be(:agent_ids) { [finding.location['kubernetes_resource']['agent_id']] }

      before do
        create(:vulnerabilities_finding, report_type: :dast)
      end

      subject(:cluster_findings) { described_class.by_location_cluster_agent(agent_ids) }

      it 'returns findings with given agent_id' do
        expect(cluster_findings).to contain_exactly(finding)
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
            links: [{ url: 'https://raw.example.com', name: 'raw_metadata_link' }]
          }.to_json
        )
      end

      subject(:links) { finding.links }

      context 'when there are no finding links' do
        it 'returns links from raw_metadata' do
          expect(links).to eq([{ 'url' => 'https://raw.example.com', 'name' => 'raw_metadata_link' }])
        end
      end

      context 'when there are finding links assigned to given finding' do
        let_it_be(:finding_link) { create(:finding_link, name: 'finding_link', url: 'https://link.example.com', finding: finding) }

        it 'returns links from finding link' do
          expect(links).to match_array([{ 'url' => 'https://link.example.com', 'name' => 'finding_link' }])
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

        before do
          stub_feature_flags(enable_vulnerability_remediations_from_records: true)
        end

        it { is_expected.to eq([remediation_hash]) }

        context 'when reading from the remediation record is diabled' do
          let(:raw_remediation) { { summary: 'foo', diff: 'bar' }.stringify_keys }

          before do
            stub_feature_flags(enable_vulnerability_remediations_from_records: false)

            raw_metadata = { remediations: [raw_remediation] }.to_json
            finding.update!({ raw_metadata: raw_metadata })
          end

          it { is_expected.to match_array([raw_remediation]) }
        end
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
            finding_uuid: finding.uuid
          )
        end

        let(:vulnerability) { create(:vulnerability, findings: [finding]) }

        context 'when there is issue link present' do
          let!(:issue_link) { create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue) }

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
            finding_uuid: finding.uuid
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
            finding_uuid: finding.uuid
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
          finding_uuid: finding.uuid
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
            finding_uuid: finding_2.uuid
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
          stub_feature_flags(deprecate_vulnerabilities_feedback: false)
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

    describe '#image' do
      let(:finding) { build(:vulnerabilities_finding, :with_container_scanning_metadata) }
      let(:expected_location) { finding.metadata['location']['image'] }

      subject { finding.image }

      it { is_expected.to eq(expected_location) }
    end

    describe '#evidence' do
      subject { finding.evidence }

      shared_examples 'evidence schema' do
        it 'matches evidence schema' do
          example_evidence = evidence.with_indifferent_access

          is_expected.to match a_hash_including(
            summary: example_evidence['summary']
          )

          is_expected.to match a_hash_including(
            request: {
              headers: [
                {
                  name: example_evidence['request']['headers'][0]['name'],
                  value: example_evidence['request']['headers'][0]['value']
                }
              ],
              url: example_evidence['request']['url'],
              method: example_evidence['request']['method'],
              body: example_evidence['request']['body']
            }
          )

          is_expected.to match a_hash_including(
            response: {
              headers: [
                {
                  name: example_evidence['response']['headers'][0]['name'],
                  value: example_evidence['response']['headers'][0]['value']
                }
              ],
              reason_phrase: example_evidence['response']['reason_phrase'],
              status_code: example_evidence['response']['status_code'],
              body: example_evidence['request']['body']
            },
            source: {
              id: example_evidence.dig('source', 'id'),
              name: example_evidence.dig('source', 'name'),
              url: example_evidence.dig('source', 'url')
            }
          )

          is_expected.to match a_hash_including(
            supporting_messages: [
              {
                name: example_evidence.dig('supporting_messages')[0].dig('name'),
                request: {
                  headers: [
                    {
                      name: example_evidence.dig('supporting_messages')[0].dig('request', 'headers')[0].dig('name'),
                      value: example_evidence.dig('supporting_messages')[0].dig('request', 'headers')[0].dig('value')
                    }
                  ],
                  url: example_evidence.dig('supporting_messages')[0].dig('request', 'url'),
                  method: example_evidence.dig('supporting_messages')[0].dig('request', 'method'),
                  body: example_evidence.dig('supporting_messages')[0].dig('request', 'body')
                },
                response: example_evidence.dig('supporting_messages')[0].dig('response')
              },
              {
                name: example_evidence.dig('supporting_messages')[1].dig('name'),
                request: {
                  headers: [
                    {
                      name: example_evidence.dig('supporting_messages')[1].dig('request', 'headers')[0].dig('name'),
                      value: example_evidence.dig('supporting_messages')[1].dig('request', 'headers')[0].dig('value')
                    }
                  ],
                  url: example_evidence.dig('supporting_messages')[1].dig('request', 'url'),
                  method: example_evidence.dig('supporting_messages')[1].dig('request', 'method'),
                  body: example_evidence.dig('supporting_messages')[1].dig('request', 'body')
                },
                response: {
                  headers: [
                    {
                      name: example_evidence.dig('supporting_messages')[1].dig('response', 'headers')[0].dig('name'),
                      value: example_evidence.dig('supporting_messages')[1].dig('response', 'headers')[0].dig('value')
                    }
                  ],
                  reason_phrase: example_evidence.dig('supporting_messages')[1].dig('response', 'reason_phrase'),
                  status_code: example_evidence.dig('supporting_messages')[1].dig('response', 'status_code'),
                  body: example_evidence.dig('supporting_messages')[1].dig('response', 'body')
                }
              }
            ]
          )
        end
      end

      context 'without finding_evidence' do
        context 'has an evidence fields' do
          let(:finding) { create(:vulnerabilities_finding) }
          let(:evidence) { finding.metadata['evidence'] }

          include_examples 'evidence schema'
        end

        context 'has no evidence summary when evidence is present, summary is not' do
          let(:finding) { create(:vulnerabilities_finding, raw_metadata: { evidence: {} }) }

          it { is_expected.to be_nil }
        end
      end

      context 'with finding_evidence' do
        let(:finding_evidence) { build(:vulnerabilties_finding_evidence) }
        let(:finding) { finding_evidence.finding }
        let(:evidence) { finding_evidence.data }

        before do
          finding_evidence.data[:summary] = "finding_evidence Summary"
          finding_evidence.save!
        end

        include_examples 'evidence schema'
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

      context 'when cve text field is present' do
        let(:finding) { build(:vulnerabilities_finding, cve: 'Vulnerability cve') }

        it { is_expected.to eq(expected_cve) }
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
        expect(finding1.eql?(finding2)).to be(vulnerability_finding_signatures)
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
        let(:same_scope_offset) { false }

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
            next unless vulnerability_finding_signatures

            create_signatures
            expect(finding1.eql?(finding2)).to be(should_match)
          end
        end
      end
    end
  end

  describe '.by_location_fingerprints' do
    let(:finding) { create(:vulnerabilities_finding) }

    subject { described_class.by_location_fingerprints(finding.location_fingerprint) }

    it { is_expected.to contain_exactly(finding) }
  end

  describe '.excluding_uuids' do
    let(:finding_1) { create(:vulnerabilities_finding) }
    let(:finding_2) { create(:vulnerabilities_finding) }
    let(:finding_3) { create(:vulnerabilities_finding) }

    subject { described_class.excluding_uuids([finding_1.uuid, finding_3.uuid]) }

    it { is_expected.to contain_exactly(finding_2) }
  end

  describe "#vulnerable_code" do
    let_it_be(:source_code) do
      <<~SOURCE
      #include <stdio.h>

      int main(int argc, char *argv[])
      {
        char buf[8];
        memcpy(&buf, "123456789");
        printf("hello, world!");
      }
      SOURCE
    end

    let_it_be(:project) do
      create(:project, :custom_repo, files: {
        'src/main.c' => source_code
      })
    end

    let_it_be(:finding) do
      create(:vulnerabilities_finding).tap do |finding|
        finding.project = project
        finding.location['file'] = 'src/main.c'
      end
    end

    subject { finding.vulnerable_code }

    context "with a start and end line number" do
      before do
        finding.location['start_line'] = 5
        finding.location['end_line'] = 6
      end

      it 'returns the vulnerables lines of code' do
        vulnerable_lines = <<-LINES
  char buf[8];
  memcpy(&buf, "123456789");
        LINES
        expect(subject).to eq(vulnerable_lines)
      end
    end

    context "with a start line number but no end line number" do
      before do
        finding.location['start_line'] = 6
        finding.location.delete('end_line')
      end

      it 'returns the single line of code' do
        vulnerable_lines = <<-LINES
  memcpy(&buf, "123456789");
        LINES
        expect(subject).to eq(vulnerable_lines)
      end
    end

    context "without any line numbers" do
      before do
        finding.location.delete('start_line')
        finding.location.delete('end_line')
      end

      it 'returns the entire file' do
        expect(subject).to eq(source_code)
      end
    end
  end
end
