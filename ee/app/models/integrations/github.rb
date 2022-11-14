# frozen_string_literal: true

module Integrations
  class Github < Integration
    include Gitlab::Routing

    delegate :api_url, :owner, :repository_name, to: :remote_project

    validates :token, presence: true, if: :activated?
    validates :repository_url, public_url: true, allow_blank: true

    attribute :pipeline_events, default: true

    field :token,
      type: 'password',
      required: true,
      placeholder: "8d3f016698e...",
      non_empty_password_title: -> { s_('ProjectService|Enter new token') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
      help: -> { token_field_help }

    field :repository_url,
      title: -> { s_('GithubIntegration|Repository URL') },
      required: true,
      exposes_secrets: true,
      placeholder: 'https://github.com/owner/repository'

    field :static_context,
      type: 'checkbox',
      title: -> { s_('GithubIntegration|Static status check names (optional)') },
      checkbox_label: -> { s_('GithubIntegration|Enable static status check names') },
      help: -> { static_context_field_help }

    def initialize_properties
      return if properties.present?

      self.static_context = true
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

    def self.static_context_field_help
      learn_more_link_url = ::Gitlab::Routing.url_helpers.help_page_path('user/project/integrations/github', anchor: 'static-or-dynamic-status-check-names')
      learn_more_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: learn_more_link_url }
      s_('GithubIntegration|Select this if you want GitHub to mark status checks as "Required". %{learn_more_link_start}Learn more%{learn_more_link_end}.').html_safe % { learn_more_link_start: learn_more_link_start, learn_more_link_end: '</a>'.html_safe }
    end

    def self.token_field_help
      token_url = 'https://github.com/settings/tokens'
      token_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: token_url }
      s_('GithubIntegration|Create a %{token_link_start}personal access token%{token_link_end} with %{status_html} access granted and paste it here.').html_safe % { token_link_start: token_link_start, token_link_end: '</a>'.html_safe, status_html: '<code>repo:status</code>'.html_safe }
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
      result = notifier.notify(status_message.sha,
        status_message.status,
        status_message.status_options)

      # The response result as defined in the documentation
      # below carries several unnecessary fields so we filter
      # them using a finite list of fields:
      # https://docs.github.com/en/rest/commits/statuses#create-a-commit-status
      log_info(
        "GitHub Commit Status update API call succeeded",
        {
          github_response: result&.try(
            :slice,
            :url, :id, :node_id, :state,
            :description, :target_url, :context,
            :created_at, :updated_at),
          github_response_status: notifier.last_client_response&.status,
          pipeline_id: status_message.pipeline_id,
          pipeline_status: status_message.status
        }
      )

      result
    end

    def notifier
      @notifier ||= StatusNotifier.new(token, remote_repo_path, api_endpoint: api_url)
    end

    def remote_repo_path
      "#{owner}/#{repository_name}"
    end
  end
end
