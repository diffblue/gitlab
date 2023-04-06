# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::IntegrationsHelper do
  include Devise::Test::ControllerHelpers

  let(:controller_class) do
    helper_mod = described_class

    # rubocop:disable Rails/ApplicationController
    Class.new(ActionController::Base) do
      include helper_mod
      include ActionView::Helpers::AssetUrlHelper

      def slack_auth_project_settings_slack_url(project)
        "http://some-path/project/1"
      end
    end
    # rubocop:enable Rails/ApplicationController
  end

  let_it_be_with_refind(:project) { create(:project) }

  subject { controller_class.new }

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

    it 'does not include Slack-specific fields' do
      is_expected.not_to include(:upgrade_slack_url)
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

    context 'with a GitLab Slack App integration' do
      let(:integration) { build(:gitlab_slack_application_integration, project: project) }

      before do
        stub_ee_application_setting(slack_app_id: 'MOCK_APP_ID')
      end

      it 'includes Slack app upgrade URL' do
        redirect_url = "http://test.host/#{project.full_path}/-/settings/slack/slack_auth"

        expect(form_data[:upgrade_slack_url]).to start_with(
          [
            Projects::SlackApplicationInstallService::SLACK_AUTHORIZE_URL,
            '?client_id=MOCK_APP_ID',
            "&redirect_uri=#{CGI.escape(redirect_url)}"
          ].join
        )
      end

      it 'includes the flag to upgrade Slack app, set to true' do
        expect(form_data[:should_upgrade_slack]).to eq 'true'
      end

      context 'when the integration includes all necessary scopes' do
        let(:integration) { create(:gitlab_slack_application_integration, :all_features_supported, project: project) }

        it 'includes the flag to upgrade Slack app, set to false' do
          expect(form_data[:should_upgrade_slack]).to eq 'false'
        end
      end
    end
  end

  describe '#add_to_slack_link' do
    let(:slack_link) { subject.add_to_slack_link(project, 'A12345') }
    let(:query) { Rack::Utils.parse_query(URI.parse(slack_link).query) }

    before do
      expect(subject).to receive(:form_authenticity_token).and_return('a token')
    end

    it 'returns the endpoint URL with all needed params' do
      expect(slack_link).to start_with(Projects::SlackApplicationInstallService::SLACK_AUTHORIZE_URL)
      expect(slack_link).to include('&state=a+token')

      expect(query).to include(
        'scope' => 'commands,chat:write,chat:write.public',
        'client_id' => 'A12345',
        'redirect_uri' => subject.slack_auth_project_settings_slack_url(project),
        'state' => 'a token'
      )
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

  describe '#gitlab_slack_application_data' do
    let_it_be(:projects) { create_list(:project, 3) }

    def relation
      Project.id_in(projects.pluck(:id)).inc_routes
    end

    let(:request) do
      double(
        :Request,
        optional_port: nil,
        path_parameters: {},
        protocol: 'https',
        routes: nil,
        env: { 'warden' => warden },
        engine_script_name: nil,
        original_script_name: nil,
        host: 'example.com'
      )
    end

    before do
      allow(subject).to receive(:request).and_return(request)
    end

    it 'includes the required keys' do
      additions = subject.gitlab_slack_application_data(relation)
      expect(additions.keys).to include(
        :projects,
        :sign_in_path,
        :is_signed_in,
        :slack_link_path,
        :gitlab_logo_path,
        :slack_logo_path
      )
    end

    it 'does not suffer from N+1 performance issues' do
      baseline = ActiveRecord::QueryRecorder.new { subject.gitlab_slack_application_data(relation.limit(1)) }

      expect do
        subject.gitlab_slack_application_data(relation)
      end.not_to exceed_query_limit(baseline)
    end

    it 'serializes nil projects without error' do
      expect(subject.gitlab_slack_application_data(nil)).to include(projects: '[]')
    end
  end
end
