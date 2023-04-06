# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VulnerabilitiesHelper, feature_category: :vulnerability_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:finding) { create(:vulnerabilities_finding, :with_pipeline, project: project, severity: :high) }

  let(:vulnerability) { create(:vulnerability, title: "My vulnerability", project: project, findings: [finding]) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  RSpec.shared_examples 'vulnerability properties' do
    let(:vulnerability_serializer_hash) do
      vulnerability.slice(
        :id,
        :title,
        :state,
        :severity,
        :confidence,
        :report_type,
        :resolved_on_default_branch,
        :project_default_branch,
        :resolved_by_id,
        :dismissed_by_id,
        :confirmed_by_id
      )
    end

    let(:finding_serializer_hash) do
      finding.slice(
        :description,
        :identifiers,
        :links,
        :location,
        :name,
        :issue_feedback,
        :project,
        :remediations,
        :solution,
        :uuid,
        :details
      )
    end

    let(:desired_serializer_fields) { %i[metadata identifiers name issue_feedback merge_request_feedback project project_fingerprint scanner uuid details dismissal_feedback false_positive state_transitions issue_links merge_request_links] }

    before do
      vulnerability_serializer_stub = instance_double("VulnerabilitySerializer")
      expect(VulnerabilitySerializer).to receive(:new).and_return(vulnerability_serializer_stub)
      expect(vulnerability_serializer_stub).to receive(:represent).with(vulnerability).and_return(vulnerability_serializer_hash)

      finding_serializer_stub = instance_double("Vulnerabilities::FindingSerializer")
      expect(Vulnerabilities::FindingSerializer).to receive(:new).and_return(finding_serializer_stub)
      expect(finding_serializer_stub).to receive(:represent).with(finding, only: desired_serializer_fields).and_return(finding_serializer_hash)
    end

    around do |example|
      freeze_time { example.run }
    end

    it 'has expected vulnerability properties' do
      expect(subject).to include(
        timestamp: Time.now.to_i,
        new_issue_url: "/#{project.full_path}/-/issues/new?vulnerability_id=#{vulnerability.id}",
        create_jira_issue_url: nil,
        related_jira_issues_path: "/#{project.full_path}/-/integrations/jira/issues?vulnerability_ids%5B%5D=#{vulnerability.id}",
        jira_integration_settings_path: "/#{project.full_path}/-/settings/integrations/jira/edit",
        create_mr_url: "/#{project.full_path}/-/vulnerability_feedback",
        discussions_url: "/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/discussions",
        notes_url: "/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/notes",
        related_issues_help_path: kind_of(String),
        pipeline: anything,
        can_modify_related_issues: false
      )
    end

    context 'when the issues are disabled for the project' do
      before do
        allow(project).to receive(:issues_enabled?).and_return(false)
      end

      it 'has `new_issue_url` set as nil' do
        expect(subject).to include(new_issue_url: nil)
      end
    end
  end

  describe '#vulnerability_details' do
    before do
      allow(helper).to receive(:can?).and_return(true)
    end

    subject { helper.vulnerability_details(vulnerability, pipeline) }

    describe '[:can_modify_related_issues]' do
      context 'with security dashboard feature enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        context 'when user can manage related issues' do
          before do
            project.add_developer(user)
          end

          it { is_expected.to include(can_modify_related_issues: true) }
        end

        context 'when user cannot manage related issues' do
          it { is_expected.to include(can_modify_related_issues: false) }
        end
      end

      context 'with security dashboard feature disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
          project.add_developer(user)
        end

        it { is_expected.to include(can_modify_related_issues: false) }
      end
    end

    context 'when pipeline exists' do
      subject { helper.vulnerability_details(vulnerability, pipeline) }

      include_examples 'vulnerability properties'

      it 'returns expected pipeline data' do
        expect(subject[:pipeline]).to include(
          id: pipeline.id,
          created_at: pipeline.created_at.iso8601,
          url: be_present
        )
      end
    end

    context 'when pipeline is nil' do
      subject { helper.vulnerability_details(vulnerability, nil) }

      include_examples 'vulnerability properties'

      it 'returns no pipeline data' do
        expect(subject[:pipeline]).to be_nil
      end
    end

    context 'dismissal descriptions' do
      let(:expected_descriptions) do
        {
          acceptable_risk: "The vulnerability is known, and has not been remediated or mitigated, but is considered to be an acceptable business risk.",
          false_positive: "An error in reporting in which a test result incorrectly indicates the presence of a vulnerability in a system when the vulnerability is not present.",
          mitigating_control: "A management, operational, or technical control (that is, safeguard or countermeasure) employed by an organization that provides equivalent or comparable protection for an information system.",
          used_in_tests: "The finding is not a vulnerability because it is part of a test or is test data.",
          not_applicable: "The vulnerability is known, and has not been remediated or mitigated, but is considered to be in a part of the application that will not be updated."
        }
      end

      let(:translated_descriptions) do
        # Use dynamic translations via N_(...)
        expected_descriptions.values.map { |description| _(description) }
      end

      it 'includes translated dismissal descriptions' do
        Gitlab::I18n.with_locale(:en) do
          # Force loading of the class and configured translations
          Vulnerabilities::DismissalReasonEnum.translated_descriptions
        end

        Gitlab::I18n.with_locale(:zh_CN) do
          expect(subject[:dismissal_descriptions].keys).to eq(expected_descriptions.keys)
          expect(subject[:dismissal_descriptions].values).to eq(translated_descriptions)
        end
      end
    end
  end

  describe '#create_jira_issue_url_for' do
    subject { helper.create_jira_issue_url_for(vulnerability) }

    let(:jira_integration) { double('Integrations::Jira', new_issue_url_with_predefined_fields: 'https://jira.example.com/new') }

    before do
      allow(helper).to receive(:can?).and_return(true)
      allow(vulnerability.project).to receive(:jira_integration).and_return(jira_integration)
    end

    context 'with jira vulnerabilities integration enabled' do
      before do
        allow(project).to receive(:jira_vulnerabilities_integration_enabled?).and_return(true)
        allow(project).to receive(:configured_to_create_issues_from_vulnerabilities?).and_return(true)
      end

      context 'when the given object is a vulnerability' do
        let(:expected_jira_issue_description) do
          <<-JIRA.strip_heredoc
            Issue created from vulnerability [#{vulnerability.id}|http://localhost/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}]

            h3. Description:

            Description of My vulnerability

            * Severity: high
            * Confidence: medium
            * Location: [maven/src/main/java/com/gitlab/security_products/tests/App.java:29|http://localhost/#{project.full_path}/-/blob/b83d6e391c22777fca1ed3012fce84f633d7fed0/maven/src/main/java/com/gitlab/security_products/tests/App.java#L29]

            #### Evidence

            * Method: `GET`
            * URL: http://goat:8080/WebGoat/logout

            ##### Request:

            ```
            Accept : */*
            ```

            ##### Response:

            ```
            Content-Length : 0
            ```

            ### Solution:

            See vulnerability [#{vulnerability.id}|http://localhost/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}] for any Solution details.


            h3. Links:

            * [Cipher does not check for integrity first?|https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first]


            h3. Scanner:

            * Name: Find Security Bugs
          JIRA
        end

        it 'delegates rendering URL to Integrations::Jira' do
          expect(jira_integration).to receive(:new_issue_url_with_predefined_fields).with("Investigate vulnerability: #{vulnerability.title}", expected_jira_issue_description)

          subject
        end

        context 'when scan property is empty' do
          before do
            vulnerability.finding.scan = nil
          end

          it 'renders description using dedicated template without raising error' do
            expect(jira_integration).to receive(:new_issue_url_with_predefined_fields).with("Investigate vulnerability: #{vulnerability.title}", expected_jira_issue_description)

            subject
          end
        end
      end

      context 'when the given object is an unpersisted finding' do
        let(:vulnerability) { build(:vulnerabilities_finding, :with_remediation, project: project) }
        let(:expected_jira_issue_description) do
          <<~TEXT
            h3. Description:

            The cipher does not provide data integrity update 1

            * Severity: high
            * Confidence: medium


            h3. Links:

            * [Cipher does not check for integrity first?|https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first]


            h3. Scanner:

            * Name: Find Security Bugs
          TEXT
        end

        it 'delegates rendering URL to Integrations::Jira' do
          expect(jira_integration).to receive(:new_issue_url_with_predefined_fields).with("Investigate vulnerability: #{vulnerability.name}", expected_jira_issue_description)

          subject
        end
      end

      context 'when the given object is a Security::Finding' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:scan) { create(:security_scan, pipeline: pipeline) }
        let(:vulnerability) { create(:security_finding, :with_finding_data, scan: scan) }
        let(:expected_jira_issue_description) do
          <<~TEXT
            h3. Description:

            The cipher does not provide data integrity update 1

            * Severity: critical
            * Confidence: high


            h3. Links:

            * [Cipher does not check for integrity first?|https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first]


            h3. Scanner:

            * Name: Find Security Bugs
            * Type: dast
          TEXT
        end

        it 'delegates rendering URL to Integrations::Jira' do
          expect(jira_integration).to receive(:new_issue_url_with_predefined_fields).with("Investigate vulnerability: #{vulnerability.name}", expected_jira_issue_description)

          subject
        end
      end
    end

    context 'with jira vulnerabilities integration disabled' do
      before do
        allow(project).to receive(:jira_vulnerabilities_integration_enabled?).and_return(false)
        allow(project).to receive(:configured_to_create_issues_from_vulnerabilities?).and_return(false)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#vulnerability_finding_data' do
    subject { helper.vulnerability_finding_data(vulnerability) }

    it 'returns finding information' do
      expect(subject.to_h).to match(
        description: finding.description,
        description_html: match(%r<p data-sourcepos.*?\<\/p>),
        identifiers: kind_of(Array),
        issue_feedback: anything,
        links: finding.links,
        location: finding.location,
        name: finding.name,
        merge_request_feedback: anything,
        project: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        project_fingerprint: finding.project_fingerprint,
        remediations: finding.remediations,
        solution: kind_of(String),
        solution_html: match(%r<p data-sourcepos.*?\<\/p>),
        evidence: kind_of(String),
        scanner: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        request: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        response: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        evidence_source: anything,
        assets: kind_of(Array),
        supporting_messages: kind_of(Array),
        uuid: kind_of(String),
        details: kind_of(Hash),
        dismissal_feedback: anything,
        state_transitions: kind_of(Array),
        issue_links: kind_of(Array),
        merge_request_links: kind_of(Array)
      )

      expect(subject[:location]['blob_path']).to match(kind_of(String))
    end

    context 'when there is no file' do
      before do
        vulnerability.finding.location['file'] = nil
        vulnerability.finding.location.delete('blob_path')
      end

      it 'does not have a blob_path if there is no file' do
        expect(subject[:location]).not_to have_key('blob_path')
      end
    end

    context 'when deprecate_vulnerabilities_feedback is disabled' do
      before do
        stub_feature_flags(deprecate_vulnerabilities_feedback: false)
      end

      context 'with existing dismissal feedback' do
        let_it_be(:feedback) { create(:vulnerability_feedback, :comment, :dismissal, project: project, pipeline: pipeline, finding_uuid: finding.uuid) }

        it 'returns dismissal feedback information', :aggregate_failures do
          dismissal_feedback = subject[:dismissal_feedback]
          expect(dismissal_feedback[:dismissal_reason]).to eq(feedback.dismissal_reason)
          expect(dismissal_feedback[:comment_details][:comment]).to eq(feedback.comment)
        end
      end
    end

    context 'when deprecate_vulnerabilities_feedback is enabled' do
      context 'with existing vulnerability_state_transition, issue link and merge request link' do
        let_it_be(:feedback) { create(:vulnerability_feedback, :comment, :dismissal, project: project, pipeline: pipeline, finding_uuid: finding.uuid) }
        let!(:vulnerability_state_transition) { create(:vulnerability_state_transition, vulnerability: vulnerability, to_state: :dismissed, comment: "Dismissal Comment", dismissal_reason: :false_positive) }
        let!(:vulnerabilities_issue_link) { create(:vulnerabilities_issue_link, vulnerability: vulnerability) }
        let!(:vulnerabilities_merge_request_link) { create(:vulnerabilities_merge_request_link, vulnerability: vulnerability) }

        it 'returns finding link associations', :aggregate_failures do
          expect(subject[:state_transitions].first[:comment]).to eq vulnerability_state_transition.comment
          expect(subject[:issue_links].first[:issue_iid]).to eq vulnerabilities_issue_link.issue.iid
          expect(subject[:merge_request_links].first[:merge_request_iid]).to eq vulnerabilities_merge_request_link.merge_request.iid
        end

        # Deprecated information is still returned when deprecate_vulnerabilities_feedback is enabled but should not be used.
        it 'returns dismissal feedback information', :aggregate_failures do
          dismissal_feedback = subject[:dismissal_feedback]
          expect(dismissal_feedback[:dismissal_reason]).to eq(feedback.dismissal_reason)
          expect(dismissal_feedback[:comment_details][:comment]).to eq(feedback.comment)
        end
      end
    end

    context 'with markdown field for description' do
      context 'when vulnerability has no description and finding has description' do
        before do
          vulnerability.description = nil
          vulnerability.finding.description = '# Finding'
        end

        it 'returns finding information' do
          rendered_markdown = '<h1 data-sourcepos="1:1-1:9" dir="auto">&#x000A;<a id="user-content-finding" class="anchor" href="#finding" aria-hidden="true"></a>Finding</h1>'

          expect(subject[:description_html]).to eq(rendered_markdown)
        end
      end

      context 'when vulnerability has description and finding has description' do
        before do
          vulnerability.description = '# Vulnerability'
          vulnerability.finding.description = '# Finding'
        end

        it 'returns finding information' do
          rendered_markdown = '<h1 data-sourcepos="1:1-1:15" dir="auto">&#x000A;<a id="user-content-vulnerability" class="anchor" href="#vulnerability" aria-hidden="true"></a>Vulnerability</h1>'

          expect(subject[:description_html]).to eq(rendered_markdown)
        end
      end
    end
  end

  describe '#vulnerability_scan_data?' do
    subject { helper.vulnerability_scan_data?(vulnerability) }

    context 'scanner present' do
      before do
        allow(vulnerability).to receive(:scanner).and_return(true)
      end

      it { is_expected.to be_truthy }
    end

    context 'scan present' do
      before do
        allow(vulnerability).to receive(:scanner).and_return(false)
        allow(vulnerability).to receive(:scan).and_return(true)
      end

      it { is_expected.to be_truthy }
    end

    context 'neither scan nor scanner being present' do
      before do
        allow(vulnerability).to receive(:scanner).and_return(false)
        allow(vulnerability).to receive(:scan).and_return(false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
