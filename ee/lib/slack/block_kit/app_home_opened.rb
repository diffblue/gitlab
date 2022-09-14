# frozen_string_literal: true

# Builds the BlockKit UI JSON payload to respond to the Slack `app_home_opened` event.
#
# See:
# - https://api.slack.com/block-kit/building
# - https://api.slack.com/events/app_home_opened
module Slack
  module BlockKit
    class AppHomeOpened
      include ActionView::Helpers::AssetUrlHelper

      def initialize(slack_user_id, slack_workspace_id, slack_gitlab_user_connection, slack_installation)
        @slack_user_id = slack_user_id
        @slack_workspace_id = slack_workspace_id
        @slack_gitlab_user_connection = slack_gitlab_user_connection
        @slack_installation = slack_installation
      end

      def build
        {
          "type": "home",
          "blocks": [
            header,
            section_introduction,
            section_first_step_section,
            section_connect_gitlab_account,
            section_second_step,
            section_gitlab_help,
            divider,
            section_create_issues,
            image_create_issues,
            divider,
            section_run_ci_cd,
            image_run_ci_cd
          ]
        }
      end

      private

      attr_reader :slack_user_id, :slack_workspace_id, :slack_gitlab_user_connection, :slack_installation

      def header
        {
          "type": "header",
          "text": {
            "type": "plain_text",
            "text": format(
              s_("Slack|%{emoji}Welcome to GitLab for Slack!"),
              emoji: '✨ '
            ),
            "emoji": true
          }
        }
      end

      def section_introduction
        section(
          format(
            s_("Slack|View and control GitLab content while you're working in Slack. Type the command as a" \
              " message in your chat client to activate it. %{startMarkup}Learn more%{endMarkup}."),
              startMarkup: " <https://docs.gitlab.com/ee/integration/slash_commands.html|",
              endMarkup: ">"
          )
        )
      end

      def section_first_step_section
        section(
          format(
            s_("Slack|%{asterisk}Step 1.%{asterisk} Connect your GitLab account to get started."),
            asterisk: '*'
          )
        )
      end

      def section_second_step
        section(
          format(
            s_("Slack|%{asterisk}Step 2.%{asterisk} Try it out!"),
            asterisk: '*'
          )
        )
      end

      def section_gitlab_help
        section(
          format(s_("Slack|See a list of available commands: %{command})"), command: "`/gitlab help`")
        )
      end

      def section_create_issues
        section(
          format(
            s_("Slack|Create new issues from Slack: %{command}"),
            command: "`/gitlab <project alias> issue new <title> <shift+return> <description>`"
          )
        )
      end

      def section_run_ci_cd
        section(
          format(
            s_("Slack|Streamline your GitLab deployments with ChatOps. Once you've configured your" \
              " %{startMarkup}CI/CD pipelines%{endMarkup}, try: %{command}"),
              startMarkup: "<https://docs.gitlab.com/ee/ci/chatops/index.html|",
              endMarkup: ">",
              command: "`/gitlab <project alias> run <job name> <arguments>`"
          )
        )
      end

      def section_connect_gitlab_account
        if slack_gitlab_user_connection.present?
          section_gitlab_account_connected
        else
          actions_gitlab_account_not_connected
        end
      end

      def section_gitlab_account_connected
        user = slack_gitlab_user_connection.user

        section(
          format(
            s_("Slack|%{emoji}Connected to GitLab account %{account}"),
            emoji: '✅ ',
            account: "<#{Gitlab::UrlBuilder.build(user)}|#{user.to_reference}>"
          )
        )
      end

      def actions_gitlab_account_not_connected
        account_connection_url = ChatNames::AuthorizeUserService.new(
          slack_installation.integration,
          {
            team_id: slack_workspace_id,
            user_id: slack_user_id,
            team_domain: slack_workspace_id,
            user_name: 'Slack'
          }
        ).execute

        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "text": s_("Slack|Connect your GitLab account"),
                "emoji": true
              },
              "style": "primary",
              "url": account_connection_url
            }
          ]
        }
      end

      def section(text)
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": text
          }
        }
      end

      def divider
        {
          "type": "divider"
        }
      end

      def image_create_issues
        image(
          text: s_("Slack|Create a new issue"),
          filename: "slack-issue-new.gif"
        )
      end

      def image_run_ci_cd
        image(
          text: s_("Slack|Run a CI/CD job"),
          filename: "slack-run-job.gif"
        )
      end

      def image(text:, filename:)
        image_url = ActionController::Base.helpers.image_url("slack/#{filename}", host: Gitlab.config.gitlab.base_url)

        {
          "type": "image",
          "title": {
            "type": "plain_text",
            "text": text,
            "emoji": true
          },
          "image_url": image_url,
          "alt_text": text
        }
      end
    end
  end
end
