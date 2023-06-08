# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::IntegrationsHelper, feature_category: :integrations do
  let_it_be_with_refind(:project) { create(:project) }

  describe '#integration_form_data' do
    let(:integration) { build(:jenkins_integration) }

    let(:jira_fields) do
      {
        show_jira_issues_integration: 'false',
        show_jira_vulnerabilities_integration: 'false',
        enable_jira_issues: 'true',
        enable_jira_vulnerabilities: 'false',
        project_key: 'FE',
        vulnerabilities_issuetype: '10001'
      }
    end

    subject(:form_data) { helper.integration_form_data(integration, project: project) }

    it 'does not include Jira-specific fields' do
      is_expected.not_to include(*jira_fields.keys)
    end

    context 'with a Jira integration' do
      let_it_be_with_refind(:integration) { create(:jira_integration, project: project, issues_enabled: true, project_key: 'FE', vulnerabilities_enabled: true, vulnerabilities_issuetype: '10001') }

      context 'when there is no license for jira_vulnerabilities_integration' do
        before do
          allow(integration).to receive(:jira_vulnerabilities_integration_available?).and_return(false)
        end

        it 'includes default Jira fields' do
          is_expected.to include(jira_fields)
        end
      end

      context 'when all flags are enabled' do
        before do
          stub_licensed_features(jira_issues_integration: true, jira_vulnerabilities_integration: true)
        end

        it 'includes all Jira fields' do
          is_expected.to include(
            jira_fields.merge(
              show_jira_issues_integration: 'true',
              show_jira_vulnerabilities_integration: 'true',
              enable_jira_vulnerabilities: 'true'
            )
          )
        end
      end
    end
  end

  describe '#jira_issues_show_data' do
    subject { helper.jira_issues_show_data }

    before do
      allow(helper).to receive(:params).and_return({ id: 'FE-1' })
      assign(:project, project)
    end

    it 'includes Jira issues show data' do
      is_expected.to include(
        issues_show_path: "/#{project.full_path}/-/integrations/jira/issues/FE-1.json",
        issues_list_path: "/#{project.full_path}/-/integrations/jira/issues"
      )
    end
  end

  describe '#jira_issue_breadcrumb_link' do
    let(:expected_html) { '<img width="15" height="15" class="gl-mr-2 lazy" data-src="/assets/illustrations/logos/jira-d90a9462f8323a5a2d9aef3c3bbb5c8a40275419aabf3cfbe6826113162b18a1.svg" src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" /><a rel="noopener noreferrer" class="gl-display-flex gl-align-items-center gl-white-space-nowrap" href="">my-ref</a>' }

    subject { helper.jira_issue_breadcrumb_link(issue_reference) }

    context 'with a valid issue_reference' do
      let(:issue_reference) { 'my-ref' }

      it 'returns the correct HTML' do
        is_expected.to eq(expected_html)
      end
    end

    context 'when issue_reference contains HTML' do
      let(:issue_reference) { "<script>alert('XSS')</script>my-ref" }

      it 'strips all tags' do
        is_expected.to eq(expected_html)
      end
    end
  end

  describe '#zentao_issue_breadcrumb_link' do
    subject { helper.zentao_issue_breadcrumb_link(issue_json) }

    context 'with valid issue JSON' do
      let(:issue_json) { { id: "my-ref", web_url: "https://example.com" } }

      it 'returns the correct HTML' do
        is_expected.to eq('<img width="15" height="15" class="gl-mr-2 lazy" data-src="/assets/logos/zentao-91a4a40cfe1a1640cb4fcf645db75e0ce23fbb9984f649c0675e616d6ff8c632.svg" src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" /><a target="_blank" rel="noopener noreferrer" class="gl-display-flex gl-align-items-center gl-white-space-nowrap" href="https://example.com">my-ref</a>')
      end
    end

    context 'when issue_reference contains XSS' do
      let(:issue_json) { { id: "<script>alert('XSS')</script>my-ref", web_url: "javascript:alert('XSS')" } }

      it 'strips all tags and sanitizes' do
        is_expected.to eq('<img width="15" height="15" class="gl-mr-2 lazy" data-src="/assets/logos/zentao-91a4a40cfe1a1640cb4fcf645db75e0ce23fbb9984f649c0675e616d6ff8c632.svg" src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" /><a target="_blank" rel="noopener noreferrer" class="gl-display-flex gl-align-items-center gl-white-space-nowrap">my-ref</a>')
      end
    end
  end
end
