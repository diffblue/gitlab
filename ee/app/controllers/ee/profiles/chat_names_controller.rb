# frozen_string_literal: true

module EE
  module Profiles
    module ChatNamesController
      extend ::Gitlab::Utils::Override

      private

      override :integration_name
      def integration_name
        return s_('Integrations|GitLab for Slack app') if slack_app_params?

        super
      end

      def slack_app_params?
        chat_name_params[:team_id].start_with?('T') &&
          chat_name_params[:chat_id].start_with?('U', 'W')
      end
    end
  end
end
