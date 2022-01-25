# frozen_string_literal: true

module EE
  module Integration
    extend ActiveSupport::Concern

    prepended do
      scope :vulnerability_hooks, -> { where(vulnerability_events: true, active: true) }
    end

    EE_COM_PROJECT_SPECIFIC_INTEGRATION_NAMES = %w[
      gitlab_slack_application
    ].freeze

    EE_PROJECT_SPECIFIC_INTEGRATION_NAMES = %w[
      github
    ].freeze

    class_methods do
      extend ::Gitlab::Utils::Override

      override :project_specific_integration_names
      def project_specific_integration_names
        integrations = super + EE_PROJECT_SPECIFIC_INTEGRATION_NAMES
        integrations += EE_COM_PROJECT_SPECIFIC_INTEGRATION_NAMES if ::Gitlab.dev_env_or_com?
        integrations
      end
    end
  end
end
