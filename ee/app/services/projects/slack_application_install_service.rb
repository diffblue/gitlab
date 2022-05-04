# frozen_string_literal: true

module Projects
  class SlackApplicationInstallService < BaseService
    include Gitlab::Routing

    # These scopes are requested when installing the app, additional scopes
    # will need reauthorization.
    # https://api.slack.com/authentication/oauth-v2#asking
    DEFAULT_SCOPES = %w[commands].freeze

    # Endpoint to initiate the OAuth flow, redirects to Slack's authorization screen
    # https://api.slack.com/authentication/oauth-v2#asking
    SLACK_AUTHORIZE_URL = 'https://slack.com/oauth/v2/authorize'
    SLACK_AUTHORIZE_URL_LEGACY = 'https://slack.com/oauth/authorize'

    # Endpoint to exchange the temporary authorization code for an access token
    # https://api.slack.com/authentication/oauth-v2#exchanging
    SLACK_EXCHANGE_TOKEN_URL = 'https://slack.com/api/oauth.v2.access'
    SLACK_EXCHANGE_TOKEN_URL_LEGACY = 'https://slack.com/api/oauth.access'

    def self.use_v2_flow?
      Feature.enabled?(:slack_app_use_v2_flow)
    end

    def execute
      slack_data = exchange_slack_token

      return error("Slack: #{slack_data['error']}") unless slack_data['ok']

      integration = project.gitlab_slack_application_integration \
        || project.create_gitlab_slack_application_integration!

      installation = integration.slack_integration || integration.build_slack_integration

      if using_v2_flow?
        installation.bot_user_id = slack_data['bot_user_id']
        installation.bot_access_token = slack_data['access_token']
      else
        installation.bot_user_id = nil
        installation.bot_access_token = nil
      end

      installation.update!(
        team_id: slack_data.dig('team', 'id'),
        team_name: slack_data.dig('team', 'name'),
        alias: project.full_path,
        user_id: slack_data.dig('authed_user', 'id')
      )

      # NOTE: Skip this in v2 because we don't receive a user name anymore.
      # This means the installing user will have to manually authorize
      # through Slack if they want to use the app, like other users.
      #
      # Can be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/356005
      make_sure_chat_name_created(slack_data) unless using_v2_flow?

      success
    end

    private

    # The `v2=true` param is passed through the redirect_uri, so we can use
    # this to keep the whole flow in the same version when the FF is toggled.
    def using_v2_flow?
      params[:v2] == 'true'
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def make_sure_chat_name_created(slack_data)
      integration = project.gitlab_slack_application_integration

      chat_name = ChatName.find_by(
        service_id: integration.id,
        team_id: slack_data['team_id'],
        chat_id: slack_data['user_id']
      )

      unless chat_name
        ChatName.find_or_create_by!(
          service_id: integration.id,
          team_id: slack_data['team_id'],
          team_domain: slack_data['team_name'],
          chat_id: slack_data['user_id'],
          chat_name: slack_data['user_name'],
          user: current_user
        )
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def exchange_slack_token
      query = {
        client_id: Gitlab::CurrentSettings.slack_app_id,
        client_secret: Gitlab::CurrentSettings.slack_app_secret,
        code: params[:code],
        # NOTE: Needs to match the `redirect_uri` passed to the authorization endpoint,
        # otherwise we get a `bad_redirect_uri` error.
        redirect_uri: slack_auth_project_settings_slack_url(project)
      }

      if using_v2_flow?
        exchange_url = SLACK_EXCHANGE_TOKEN_URL
        query[:redirect_uri] += '?v2=true'
      else
        exchange_url = SLACK_EXCHANGE_TOKEN_URL_LEGACY
      end

      data = Gitlab::HTTP.get(exchange_url, query: query).to_hash

      # Tweak the format of the legacy response so we can treat them the same
      unless using_v2_flow?
        data['authed_user'] ||= { 'id' => data['user_id'] }
        data['team'] ||= { 'id' => data['team_id'], 'name' => data['team_name'] }
      end

      data
    end
  end
end
