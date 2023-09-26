# frozen_string_literal: true

module Security
  module Orchestration
    class CreateBotService
      attr_reader :project, :current_user, :skip_authorization

      def initialize(project, current_user, skip_authorization: false)
        @project = project
        @current_user = current_user
        @skip_authorization = skip_authorization
      end

      def execute
        return if project.security_policy_bot.present?

        if !skip_authorization && !current_user&.can?(:admin_project_member, project)
          raise Gitlab::Access::AccessDeniedError
        end

        User.transaction do
          bot_user = ::Users::AuthorizedCreateService.new(
            current_user,
            bot_user_params
          ).execute
          Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
            %w[members notification_settings events user_interacted_projects], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424290'
          ) do
            if skip_authorization
              project.add_guest(bot_user)
            else
              project.add_guest(bot_user, current_user: current_user)
            end
          end
        end
      end

      private

      def bot_user_params
        {
          name: 'GitLab Security Policy Bot',
          email: username_and_email_generator.email,
          username: username_and_email_generator.username,
          user_type: :security_policy_bot,
          skip_confirmation: true # Bot users should always have their emails confirmed.
        }
      end

      def username_and_email_generator
        Gitlab::Utils::UsernameAndEmailGenerator.new(
          username_prefix: "gitlab_security_policy_project_#{project.id}_bot",
          email_domain: "noreply.#{Gitlab.config.gitlab.host}"
        )
      end
    end
  end
end
