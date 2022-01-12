# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::IntegrationsHelper do
  include Devise::Test::ControllerHelpers

  let(:controller_class) do
    helper_mod = described_class

    Class.new(ActionController::Base) do
      include helper_mod
      include ActionView::Helpers::AssetUrlHelper

      def slack_auth_project_settings_slack_url(project)
        "http://some-path/project/1"
      end
    end
  end

  let_it_be_with_refind(:project) { create(:project) }

  subject { controller_class.new }

  describe '#integration_form_data' do
    let(:jira_fields) do
      {
        show_jira_issues_integration: 'false',
        show_jira_vulnerabilities_integration: 'false',
        enable_jira_issues: 'true',
        enable_jira_vulnerabilities: 'false',
        project_key: 'FE',
        vulnerabilities_issuetype: '10001',
        gitlab_issues_enabled: 'true',
        upgrade_plan_path: nil,
        edit_project_path: edit_project_path(project, anchor: 'js-shared-permissions')
      }
    end

    subject { helper.integration_form_data(integration) }

    before do
      assign(:project, project)
    end

    context 'with Slack integration' do
      let(:integration) { build(:integrations_slack) }

      it 'does not include Jira specific fields' do
        is_expected.not_to include(*jira_fields.keys)
      end
    end

    context 'Jira service' do
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

  describe '#add_to_slack_link' do
    it 'encodes a masked CSRF token' do
      expect(subject).to receive(:form_authenticity_token).and_return('a token')
      slack_link = subject.add_to_slack_link(project, '123456')

      expect(slack_link).to start_with('https://slack.com/oauth/authorize')
      expect(slack_link).to include('redirect_uri=http://some-path/project/1&state=a+token')
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

  describe '#gitlab_slack_application_data' do
    let_it_be(:projects) { create_list(:project, 3) }

    def relation
      Project.id_in(projects.pluck(:id)).inc_routes
    end

    let(:request) do
      double(:Request,
             optional_port: nil,
             path_parameters: {},
             protocol: 'https',
             routes: nil,
             env: { 'warden' => warden },
             engine_script_name: nil,
             original_script_name: nil,
             host: 'example.com')
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
        :gitlab_for_slack_gif_path,
        :gitlab_logo_path,
        :slack_logo_path,
        :docs_path
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
