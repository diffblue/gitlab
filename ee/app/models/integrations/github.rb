# frozen_string_literal: true

module Integrations
  class Github < Integration
    include Gitlab::Routing

    prop_accessor :token, :repository_url
    boolean_accessor :static_context

    delegate :api_url, :owner, :repository_name, to: :remote_project

    validates :token, presence: true, if: :activated?
    validates :repository_url, public_url: true, allow_blank: true

    default_value_for :pipeline_events, true

    def initialize_properties
      self.properties ||= { static_context: true }
    end

    def title
      'GitHub'
    end

    def description
      s_("GithubIntegration|Obtain statuses for commits and pull requests.")
    end

    def help
      return unless project

      docs_link = ActionController::Base.helpers.link_to _('What is repository mirroring?'), help_page_url('user/project/repository/repository_mirroring')
      s_("GithubIntegration|This requires mirroring your GitHub repository to this project. %{docs_link}" % { docs_link: docs_link }).html_safe
    end

    def self.to_param
      'github'
    end

    def fields
      learn_more_link_url = help_page_path('user/project/integrations/github', anchor: 'static-or-dynamic-status-check-names')
      learn_more_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: learn_more_link_url }
      static_context_field_help = s_('GithubIntegration|Select this if you want GitHub to mark status checks as "Required". %{learn_more_link_start}Learn more%{learn_more_link_end}.').html_safe % { learn_more_link_start: learn_more_link_start, learn_more_link_end: '</a>'.html_safe }

      token_url = 'https://github.com/settings/tokens'
      token_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: token_url }
      token_field_help = s_('GithubIntegration|Create a %{token_link_start}personal access token%{token_link_end} with %{status_html} access granted and paste it here.').html_safe % { token_link_start: token_link_start, token_link_end: '</a>'.html_safe, status_html: '<code>repo:status</code>'.html_safe }
      [
        { type: 'password',
          name: "token",
          required: true,
          placeholder: "8d3f016698e...",
          non_empty_password_title: s_('ProjectService|Enter new token'),
          non_empty_password_help: s_('ProjectService|Leave blank to use your current token.'),
          help: token_field_help },
        { type: 'text',
          name: "repository_url",
          title: s_('GithubIntegration|Repository URL'),
          required: true,
          placeholder: 'https://github.com/owner/repository' },
        { type: 'checkbox',
          name: "static_context",
          title: s_('GithubIntegration|Static status check names (optional)'),
          checkbox_label: s_('GithubIntegration|Enable static status check names'),
          help: static_context_field_help }
      ]
    end

    def self.supported_events
      %w(pipeline)
    end

    def testable?
      project&.ci_pipelines&.any?
    end

    def execute(data)
      return if disabled? || invalid? || irrelevant_result?(data)

      status_message = StatusMessage.from_pipeline_data(project, self, data)

      update_status(status_message)
    end

    def test(data)
      begin
        result = execute(data)

        context = result[:context]
        by_user = result.dig(:creator, :login)
        result = "Status for #{context} updated by #{by_user}" if context && by_user
      rescue StandardError => error
        return { success: false, result: error }
      end

      { success: true, result: result }
    end

    private

    def irrelevant_result?(data)
      !external_pull_request_pipeline?(data) &&
        external_pull_request_pipelines_exist_for_sha?(data)
    end

    def external_pull_request_pipeline?(data)
      id = data.dig(:object_attributes, :id)

      external_pull_request_pipelines.id_in(id).exists?
    end

    def external_pull_request_pipelines_exist_for_sha?(data)
      sha = data.dig(:object_attributes, :sha)

      return false if sha.nil?

      external_pull_request_pipelines.for_sha(sha).exists?
    end

    def external_pull_request_pipelines
      @external_pull_request_pipelines ||= project
        .ci_pipelines
        .external_pull_request_event
    end

    def remote_project
      RemoteProject.new(repository_url)
    end

    def disabled?
      project.disabled_integrations.include?(to_param)
    end

    def update_status(status_message)
      notifier.notify(status_message.sha,
                      status_message.status,
                      status_message.status_options)
    end

    def notifier
      StatusNotifier.new(token, remote_repo_path, api_endpoint: api_url)
    end

    def remote_repo_path
      "#{owner}/#{repository_name}"
    end
  end
end
