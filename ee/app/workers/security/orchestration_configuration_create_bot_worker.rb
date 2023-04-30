# frozen_string_literal: true

module Security
  class OrchestrationConfigurationCreateBotWorker
    include ApplicationWorker

    feature_category :security_policy_management

    data_consistency :sticky

    idempotent!

    def perform(configuration_id, current_user_id)
      configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id)

      return if configuration.nil? || configuration.bot_user.present?

      current_user = User.find_by_id(current_user_id)

      return unless current_user

      bot_user = ::Users::AuthorizedCreateService.new(
        current_user,
        bot_user_params(configuration.project_id)
      ).execute

      configuration.project.add_guest(bot_user, current_user: current_user)

      configuration.update(bot_user: bot_user)
    end

    private

    def bot_user_params(project_id)
      {
        name: 'GitLab Security Policy Bot',
        email: username_and_email_generator(project_id).email,
        username: username_and_email_generator(project_id).username,
        user_type: :security_policy_bot,
        skip_confirmation: true # Bot users should always have their emails confirmed.
      }
    end

    def username_and_email_generator(project_id)
      Gitlab::Utils::UsernameAndEmailGenerator.new(
        username_prefix: "gitlab_security_policy_project_#{project_id}_bot",
        email_domain: "noreply.#{Gitlab.config.gitlab.host}"
      )
    end
  end
end
