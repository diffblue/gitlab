# frozen_string_literal: true

module Security
  module Orchestration
    class CreateBotService
      SecurityOrchestrationPolicyConfigurationHasNoProjectError = Class.new(StandardError)

      attr_reader :configuration, :current_user

      def initialize(security_orchestration_policy_configuration, current_user)
        @configuration = security_orchestration_policy_configuration
        @current_user = current_user
      end

      def execute
        raise SecurityOrchestrationPolicyConfigurationHasNoProjectError unless configuration.project?

        return if configuration.bot_user.present?

        raise Gitlab::Access::AccessDeniedError unless current_user.can?(:admin_project_member, configuration.project)

        User.transaction do
          bot_user = ::Users::AuthorizedCreateService.new(
            current_user,
            bot_user_params
          ).execute

          configuration.project.add_guest(bot_user, current_user: current_user)

          configuration.update!(bot_user: bot_user)
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
          username_prefix: "gitlab_security_policy_project_#{configuration.project_id}_bot",
          email_domain: "noreply.#{Gitlab.config.gitlab.host}"
        )
      end
    end
  end
end
