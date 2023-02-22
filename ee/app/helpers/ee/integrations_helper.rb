# frozen_string_literal: true

module EE
  module IntegrationsHelper
    extend ::Gitlab::Utils::Override

    override :project_jira_issues_integration?
    def project_jira_issues_integration?
      @project.jira_issues_integration_available? && @project.jira_integration&.issues_enabled
    end

    override :integration_form_data
    def integration_form_data(integration, project: nil, group: nil)
      form_data = super

      if integration.is_a?(Integrations::Jira)
        form_data.merge!(
          show_jira_issues_integration: project&.jira_issues_integration_available?.to_s,
          show_jira_vulnerabilities_integration: integration.jira_vulnerabilities_integration_available?.to_s,
          enable_jira_issues: integration.issues_enabled.to_s,
          enable_jira_vulnerabilities: integration.jira_vulnerabilities_integration_enabled?.to_s,
          project_key: integration.project_key,
          vulnerabilities_issuetype: integration.vulnerabilities_issuetype
        )
      end

      if integration.is_a?(::Integrations::GitlabSlackApplication)
        form_data[:upgrade_slack_url] = add_to_slack_link(project, slack_app_id)
        form_data[:should_upgrade_slack] = integration.upgrade_needed?.to_s
      end

      form_data
    end

    def add_to_slack_link(project, slack_app_id)
      query = {
        scope: SlackIntegration::SCOPES.join(','),
        client_id: slack_app_id,
        redirect_uri: slack_auth_project_settings_slack_url(project),
        state: form_authenticity_token
      }

      "#{::Projects::SlackApplicationInstallService::SLACK_AUTHORIZE_URL}?#{query.to_query}"
    end

    def gitlab_slack_application_data(projects)
      {
        projects: (projects || []).to_json(only: [:id, :name], methods: [:avatar_url, :name_with_namespace]),
        sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
        is_signed_in: current_user.present?.to_s,
        slack_link_path: slack_link_profile_slack_path,
        gitlab_logo_path: image_path('illustrations/gitlab_logo.svg'),
        slack_logo_path: image_path('illustrations/slack_logo.svg')
      }
    end

    def jira_issues_show_data
      {
        issues_show_path: project_integrations_jira_issue_path(@project, params[:id], format: :json),
        issues_list_path: project_integrations_jira_issues_path(@project)
      }
    end

    override :integration_event_title
    def integration_event_title(event)
      return _('Vulnerability') if event == 'vulnerability'

      super
    end

    override :default_integration_event_description
    def default_integration_event_description(event)
      return s_("ProjectService|Trigger event when a new, unique vulnerability is recorded. (Note: This feature requires an Ultimate plan.)") if event == 'vulnerability'

      super
    end

    def jira_issue_breadcrumb_link(issue_reference)
      external_issue_breadcrumb_link('illustrations/logos/jira.svg', issue_reference, '')
    end

    def zentao_issue_breadcrumb_link(issue)
      external_issue_breadcrumb_link('logos/zentao.svg', issue[:id], issue[:web_url], target: '_blank')
    end

    def zentao_issues_show_data
      {
        issues_show_path: project_integrations_zentao_issue_path(@project, params[:id], format: :json),
        issues_list_path: project_integrations_zentao_issues_path(@project)
      }
    end

    private

    # Use this method when dealing with issue data from external services
    # (like Jira or ZenTao).
    # Returns a sanitized `ActiveSupport::SafeBuffer` link.
    def external_issue_breadcrumb_link(img, text, href, options = {})
      icon = image_tag image_path(img), width: 15, height: 15, class: 'gl-mr-2'
      link = sanitize(
        link_to(
          strip_tags(text),
          strip_tags(href),
          options.merge(
            rel: 'noopener noreferrer',
            class: 'gl-display-flex gl-align-items-center gl-white-space-nowrap'
          )
        ),
        tags: %w(a img),
        attributes: %w(target href src loading rel class width height)
      )

      [icon, link].join.html_safe
    end
  end
end
