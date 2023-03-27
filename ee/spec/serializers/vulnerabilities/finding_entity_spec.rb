# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingEntity, feature_category: :vulnerability_management do
  let_it_be(:user) { build(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let(:scanner) { build(:vulnerabilities_scanner, project: project) }

  let(:scan) { build(:ci_reports_security_scan) }

  let(:identifiers) do
    [
      build(:vulnerabilities_identifier),
      build(:vulnerabilities_identifier)
    ]
  end

  let(:occurrence) do
    build(
      :vulnerabilities_finding,
      scanner: scanner,
      scan: scan,
      project: project,
      identifiers: identifiers,
      vulnerability_flags: flags
    )
  end

  let(:flags) do
    [
      build(:vulnerabilities_flag)
    ]
  end

  let(:dismiss_feedback) do
    build(
      :vulnerability_feedback, :sast, :dismissal,
      project: project, project_fingerprint: occurrence.project_fingerprint
    )
  end

  let(:issue_feedback) do
    build(
      :vulnerability_feedback, :sast, :issue,
      project: project, project_fingerprint: occurrence.project_fingerprint
    )
  end

  let(:request) { double('request') }

  let(:entity) do
    described_class.represent(occurrence, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json }

    before do
      stub_licensed_features(sast_fp_reduction: true)
      allow(request).to receive(:current_user).and_return(user)
    end

    it 'contains required fields' do
      expect(subject).to include(:id)
      expect(subject).to include(:name, :report_type, :severity, :confidence, :project_fingerprint)
      expect(subject).to include(:scanner, :project, :identifiers)
      expect(subject).to include(:dismissal_feedback, :issue_feedback)
      expect(subject).to include(:description, :links, :location, :remediations, :solution, :evidence)
      expect(subject).to include(:blob_path, :request, :response)
      expect(subject).to include(:scan)
      expect(subject).to include(:false_positive)
      expect(subject).to include(:assets, :evidence_source, :supporting_messages)
      expect(subject).to include(:uuid)
      expect(subject).to include(:details)
    end

    context 'false-positive' do
      it 'finds the vulnerability_finding as false_positive' do
        expect(subject[:false_positive]).to be(true)
      end

      it 'does not contain false_positive field if license is not available' do
        stub_licensed_features(sast_fp_reduction: false)

        expect(subject).not_to include(:false_positive)
      end
    end

    context 'when not allowed to admin vulnerability feedback' do
      before do
        project.add_guest(user)
      end

      it 'does not contain vulnerability feedback paths' do
        expect(subject[:create_jira_issue_url]).to be_falsey
        expect(subject[:create_vulnerability_feedback_issue_path]).to be_falsey
        expect(subject[:create_vulnerability_feedback_merge_request_path]).to be_falsey
        expect(subject[:create_vulnerability_feedback_dismissal_path]).to be_falsey
      end
    end

    context 'when allowed to admin vulnerability feedback' do
      before do
        project.add_developer(user)
      end

      it 'does not contain create jira issue path' do
        expect(subject[:create_jira_issue_url]).to be_falsey
      end

      it 'contains vulnerability feedback dismissal path' do
        expect(subject).to include(:create_vulnerability_feedback_dismissal_path)
      end

      it 'contains vulnerability feedback issue path' do
        expect(subject).to include(:create_vulnerability_feedback_issue_path)
      end

      it 'contains vulnerability feedback merge_request path' do
        expect(subject).to include(:create_vulnerability_feedback_merge_request_path)
      end

      context 'when jira service is configured' do
        let_it_be(:jira_integration) { create(:jira_integration, project: project, issues_enabled: true, project_key: 'FE', vulnerabilities_enabled: true, vulnerabilities_issuetype: '10001') }

        before do
          stub_licensed_features(jira_vulnerabilities_integration: true)
          allow_next_found_instance_of(Integrations::Jira) do |jira|
            allow(jira).to receive(:jira_project_id).and_return('11223')
          end
        end

        it 'does contains create jira issue path' do
          expect(subject[:create_jira_issue_url]).to be_present
        end
      end

      context 'when disallowed to create issue' do
        let(:project) { create(:project, issues_access_level: ProjectFeature::DISABLED) }

        it 'does not contain create jira issue path' do
          expect(subject[:create_jira_issue_url]).to be_falsey
        end

        it 'does not contain vulnerability feedback issue path' do
          expect(subject[:create_vulnerability_feedback_issue_path]).to be_falsey
        end

        it 'contains vulnerability feedback dismissal path' do
          expect(subject).to include(:create_vulnerability_feedback_dismissal_path)
        end

        it 'contains vulnerability feedback merge_request path' do
          expect(subject).to include(:create_vulnerability_feedback_merge_request_path)
        end
      end

      context 'when disallowed to create merge_request' do
        let(:project) { create(:project, merge_requests_access_level: ProjectFeature::DISABLED) }

        it 'does not contain create jira issue path' do
          expect(subject[:create_jira_issue_url]).to be_falsey
        end

        it 'does not contain vulnerability feedback merge_request path' do
          expect(subject[:create_vulnerability_feedback_merge_request_path]).to be_falsey
        end

        it 'contains vulnerability feedback issue path' do
          expect(subject).to include(:create_vulnerability_feedback_issue_path)
        end

        it 'contains vulnerability feedback dismissal path' do
          expect(subject).to include(:create_vulnerability_feedback_dismissal_path)
        end
      end
    end

    describe 'found_by_pipeline' do
      context 'when the serialized object is a vulnerability finding' do
        it { is_expected.to have_key(:found_by_pipeline) }
      end

      context 'when the serialized object is a security finding' do
        let(:occurrence) { build(:security_finding, :with_finding_data) }

        it { is_expected.not_to have_key(:found_by_pipeline) }
      end
    end
  end
end
